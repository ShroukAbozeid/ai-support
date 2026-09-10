module Ai
  class SupportAgent
    MODEL = "gpt-4.1-mini"
    MAX_OUTPUT_TOKENS = 200
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
      response = client.responses.create(parameters: client_params).deep_symbolize_keys
      ResponseHandler.new(message:, ticket:, open_ai_response: response).call
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

    def client_params
      {
        model: MODEL,
        max_output_tokens: MAX_OUTPUT_TOKENS,
        conversation: conversation_id,
        input:,
        instructions:,
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

    def input
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
