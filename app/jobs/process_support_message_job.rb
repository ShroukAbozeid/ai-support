class ProcessSupportMessageJob < ApplicationJob
  queue_as :default
  retry_on Net::ReadTimeout, wait: 5.seconds, attempts: 3

  def perform(message_id)
    message = Message.find(message_id)
    ticket = message.ticket
    ticket.update!(status: :in_progress)
    Ai::SupportAgent.new(ticket).call
    ticket.update!(status: :waiting_for_customer)
  end
end
