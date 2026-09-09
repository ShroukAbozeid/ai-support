module Ai
  class SupportAgent
    MODEL = "gpt-4.1-mini"
    MAX_OUTPUT_TOKENS = 200
    def initialize(message:)
      @message = message
      @first_response = false
    end

    def call
      response = client.responses.create(parameters: client_params)
      response.deep_symbolize_keys!

      ticket.messages.create!(
        role: :assistant,
        content: response_content(response),
        reply_to_message: message
      )
    rescue OpenAI::Error => e
      Rails.logger.error("Error processing support message: #{e.message}")
      ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    end

    private

    attr_reader :message
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
        instructions:
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

    def response_content(response)
      response.fetch(:output)
              .select { |output| output[:type] == "message" }
              .flat_map { |output| output[:content] }
              .select { |content| content[:type] == "output_text" }
              .map { |content| content[:text] }
              .join
    end

    def conversation_id
      ticket.open_ai_conversation_id || create_conversation_id
    end

    def create_conversation_id
      @first_response = true
      response = client.conversations.create(parameters: { model: MODEL })
      ticket.update!(open_ai_conversation_id: response[:id])

      response[:id]
    end
  end
end
