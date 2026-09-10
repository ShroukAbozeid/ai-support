module Ai
  class TicketClassifier
    def initialize(ticket:, response:)
      @ticket = ticket
      @response = response
    end

    def call
      return if no_changes?

      ticket.update!(
        priority: priority,
        category: category,
        requires_human: requires_human
      )
    end

    private
    attr_reader :ticket, :response

    def no_changes?
      ticket.priority == priority.to_s &&
       ticket.category == category.to_s &&
        ticket.requires_human == requires_human
    end

    def priority
      response[:priority]&.to_sym
    end

    def category
      response[:category]&.to_sym
    end

    def requires_human
      response[:requires_human]
    end
  end
end
