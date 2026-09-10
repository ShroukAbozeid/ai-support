module Ai
  class ResponseHandler
    def initialize(message:, ticket:, open_ai_response:)
      @message = message
      @ticket = ticket
      @open_ai_response = open_ai_response
    end

    def call
      handle_response
      update_ticket
      create_support_message
    end

    attr_reader :message, :ticket, :open_ai_response, :response

    def response_content_array
      open_ai_response.fetch(:output)
        .select { |output| output[:type] == "message" }
        .flat_map { |output| output[:content] }
    end

    def response_output_text
      response_content_array
              .select { |content| content[:type] == "output_text" }
              .map { |content| content[:text] }
              .join
    end

    def response_refusal
      response_content_array
              .select { |content| content[:type] == "refusal" }
              .map { |content| content[:refusal] }
              .join
    end

    def incomplete_response?
      open_ai_response[:status] == "incomplete" &&
       open_ai_response.dig(:incomplete_details, :type) == "max_output_tokens"
    end

    def validate_response!
      required_keys = SupportAgent::OUTPUT_SCHEMA[:required].map(&:to_sym)
      missing_keys = required_keys - response.keys
      raise OpenAI::Error, "Missing fields: #{missing_keys.join(', ')}" if missing_keys.any?

      raise OpenAI::Error, "Invalid category" unless Ticket.categories.keys.include?(response[:category])

      raise OpenAI::Error, "Invalid priority" unless Ticket.priorities.keys.include?(response[:priority])

      unless [ true, false ].include?(response[:requires_human])
        raise OpenAI::Error, "Invalid requires_human"
      end
    end

    def handle_response
      if incomplete_response?
        raise OpenAI::Error, "Incomplete response: max output tokens reached"
      elsif response_content_array.blank?
        raise OpenAI::Error, "No output content in the response"
      elsif response_refusal.present?
        raise OpenAI::Error, "Response refused: #{response_refusal}"
        # TODO: should we show the refusal message to the user? or just log it?
      elsif response_output_text.present?
        @response = parse_response
        validate_response!
      else
        raise OpenAI::Error, "No output content in the response"
      end
    end

    def parse_response
      JSON.parse(response_output_text, symbolize_names: true)
    end

    def update_ticket
      TicketClassifier.new(ticket:, response:).call
    end

    def create_support_message
      ticket.messages.create!(
        role: :assistant,
        content: response[:message],
        reply_to_message_id: message.id,
        open_ai_response_id: open_ai_response[:id]
      )
    end
  end
end
