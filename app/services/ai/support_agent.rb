module Ai
  class SupportAgent
    MODEL = "gpt-4.1-mini"
    MAX_OUTPUT_TOKENS = 200
    MAX_TOOL_ROUNDS = 5

    OUTPUT_SCHEMA = {
      type: :object,
      properties: {
        category: { type: :string, enum: Ticket.categories.keys },
        priority: { type: :string, enum: Ticket.priorities.keys },
        requires_human: { type: :boolean },
        message: { type: :string }
      },
      required: [ "category", "priority", "requires_human", "message" ],
      additionalProperties: false
    }

    def initialize(message:)
      @message = message
      @first_response = false
    end

    def call
      fetch_conversation_id
      response = client.responses.create(parameters: client_params(user_input)).deep_symbolize_keys
      result = ResponseHandler.new(message:, ticket:, open_ai_response: response).call
      tool_rounds = 0
      while result[:tools_output]
        tool_rounds += 1
        raise OpenAI::Error, "Too many tool calls" if tool_rounds > MAX_TOOL_ROUNDS

        response = client.responses.create(parameters: client_params(result[:tools_output])).deep_symbolize_keys
        result = ResponseHandler.new(message:, ticket:, open_ai_response: response).call
      end
    rescue OpenAI::Error => e
      Rails.logger.error("Error processing support message: #{e.message}")
      ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    end

    private

    attr_reader :message, :conversation_id
    delegate :ticket, to: :message

    def client
      @client ||= Ai::Client.new
    end

    def client_params(input)
      {
        model: MODEL,
        max_output_tokens: MAX_OUTPUT_TOKENS,
        conversation: conversation_id,
        input:,
        instructions:,
        tools: client_tools,
        text: {
          format: {
            type: :json_schema,
            name: "output_schema",
            strict: true,
            schema: OUTPUT_SCHEMA
          }
        }
      }
    end

    def client_tools
      [
        {
        type: "function",
        name: "lookup_subscription",
        description: "Lookup a subscription by ID",
        parameters: {
          type: :object,
          properties: {
            subscription_id: { type: :string }
          },
                      required: [ "subscription_id" ],
            additionalProperties: false
        }
      },
        {
        type: "function",
        name: "lookup_invoice",
        description: "Lookup an invoice by number",
        parameters: {
          type: :object,
          properties: {
            invoice_number: { type: :string }
          },
            required: [ "invoice_number" ],
            additionalProperties: false
        }
      },
        {
        type: "function",
        name: "escalate_to_human",
        description: "Escalate the ticket to a human support agent",
        parameters: {
          type: :object,
          properties: {
            ticket_id: { type: :string }
          },
            required: [ "ticket_id" ],
            additionalProperties: false
        }
      }
    ]
    end

    def user_input
      return ticket_summary if @first_response

      message.content
    end

    def instructions
      <<~TEXT
        You are a helpful customer support agent.

        Rules:
        - Be professional and concise.
        - Do not invent information.
        - If you don't have enough information, ask a question.
        - Never claim an action was performed unless the application actually performed it.
      TEXT
    end

    def ticket_summary
      <<~SUMMARY
        Subject: #{ticket.subject}
        Messages:
        #{ticket.messages.where.not(role: :app).where("created_at < ? OR (created_at = ? AND id <= ?)", message.created_at, message.created_at, message.id).order(:created_at, :id).map { |message| "#{message.role.capitalize}: #{message.content}" }.join("\n")}
      SUMMARY
    end

    def fetch_conversation_id
      @conversation_id = ticket.open_ai_conversation_id || create_conversation_id
    end

    def create_conversation_id
      @first_response = true
      response = client.conversations.create.deep_symbolize_keys
      ticket.update!(open_ai_conversation_id: response[:id])

      response[:id]
    end
  end
end
