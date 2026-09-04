class ProcessSupportMessageJob < ApplicationJob
  queue_as :default
  retry_on Net::ReadTimeout, wait: 5.seconds, attempts: 3

  def perform(message_id)
    message = Message.find(message_id)
    ticket = message.ticket

    ticket.with_lock do
      return reschedule_job(message_id) if ticket.in_progress?
      return if message.reply_to_message_id.present?

      first_pending_message = pending_messages(ticket).first
      return reschedule_job(message_id) unless first_pending_message == message

      ticket.update!(status: :in_progress)
    end

    previous_response_id =
      ticket.messages
        .where(role: :assistant)
        .where.not(open_ai_response_id: nil)
        .order(created_at: :desc, id: :desc)
        .pick(:open_ai_response_id)

    Ai::SupportAgent.new(message:, previous_response_id:).call

    ticket.with_lock do
      ticket.update!(status: :waiting_for_customer)
    end
  rescue StandardError
    ticket&.with_lock do
      ticket.update!(status: :open) if ticket.in_progress?
    end
    raise
  end

  def reschedule_job(message_id)
    ProcessSupportMessageJob.set(wait: 10.seconds).perform_later(message_id)
  end

  def pending_messages(ticket)
    answered_message_ids = ticket.messages
      .where(role: :assistant)
      .where.not(reply_to_message_id: nil)
      .select(:reply_to_message_id)

    ticket.messages
      .where(role: :customer)
      .where.not(id: answered_message_ids)
      .order(:created_at, :id)
  end
end
