class ProcessSupportMessageJob < ApplicationJob
  queue_as :default
  retry_on Net::ReadTimeout, wait: 5.seconds, attempts: 3

  def perform(message_id)
    message = Message.find(message_id)
    ticket = message.ticket

    ticket.with_lock do
      return reschedule_job(message_id) if ticket.in_progress?

      ticket.update!(status: :in_progress)
    end

    Ai::SupportAgent.new(ticket).call

    ticket.with_lock do
      ticket.update!(status: :waiting_for_customer)
    end
  end

  def reschedule_job(message_id)
    ProcessSupportMessageJob.set(wait: 10.seconds).perform_later(message_id)
  end
end
