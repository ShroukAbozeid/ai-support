module Ai
  class SupportAgent
    MODEL = "gpt-4.1-mini"
    MAX_OUTPUT_TOKENS = 200
    def initialize(message:, previous_response_id: nil)
      @message = message
      @previous_response_id = previous_response_id
    end

    def call
      response = Ai::Client.new.responses.create(parameters: client_params)
      response.deep_symbolize_keys!

      ticket.messages.create!(
        role: :assistant,
        content: response_content(response),
        open_ai_response_id: response[:id],
        reply_to_message: message
      )
    rescue Net::ReadTimeout
      raise
    rescue OpenAI::Error => e
      Rails.logger.error("Error processing support message: #{e.message}")
      ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    end

    private

    attr_reader :message, :previous_response_id
    delegate :ticket, to: :message

    def client_params
      {
        model: MODEL,
        max_output_tokens: MAX_OUTPUT_TOKENS,
        input:,
        previous_response_id:,
        instructions:
      }
    end

    def input
      if previous_response_id.present?
        message.content
      else
        ticket_summary
      end
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
  end
end
