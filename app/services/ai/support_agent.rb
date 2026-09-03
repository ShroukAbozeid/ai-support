module Ai
  class SupportAgent
    def initialize(ticket)
      @ticket = ticket
    end

    def call
      response = Ai::Client.new.responses.create(
        parameters: {
        model: "gpt-4.1-mini",
        input: prompt,
        max_output_tokens: 200
        }
      )
      content = response.deep_symbolize_keys.dig(:output, 1, :content, 0, :text)
      ticket.messages.create!(role: :assistant, content: content)
    rescue StandardError => e
      Rails.logger.error("Error processing support message: #{e.message}")
      ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    end

    private

    attr_reader :ticket

    def prompt
      <<~PROMPT
        You are a customer support agent. Please respond to the following customer support ticket:
        #{ticket_summary}
      PROMPT
    end

    def ticket_summary
      <<~SUMMARY
        Subject: #{ticket.subject}
        Messages:
        #{ticket.messages.order(:created_at).map { |message| "#{message.role.capitalize}: #{message.content}" }.join("\n")}
      SUMMARY
    end
  end
end
