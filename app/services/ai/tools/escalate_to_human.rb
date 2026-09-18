module Ai
  module Tools
    class EscalateToHuman
      def initialize(user_id:, ticket_id:)
        @user_id = user_id
        @ticket_id = ticket_id
      end

      def call
        @ticket = Ticket.find_by(id: ticket_id, user_id:)
        raise ActiveRecord::RecordNotFound, "Ticket not found" unless ticket

        ticket.update!(requires_human: true)
        # TODO: Send escalation email
      end

      attr_reader :user_id, :ticket_id, :ticket
    end
  end
end
