class ProcessSupportMessageJob < ApplicationJob
  queue_as :default
  retry_on Net::ReadTimeout,
           Faraday::TimeoutError,
           Net::OpenTimeout,
           Timeout::Error,
           Faraday::RequestTimeoutError,
           Faraday::ConnectionFailed,
           Faraday::ServerError,
            wait: 5.seconds, attempts: 3, report: true
  after_discard do |job, exception|
    job.handle_failure(exception)
  end

  NON_RETRIABLE_EXCEPTIONS = [
    OpenAI::Error, Faraday::BadRequestError, Faraday::UnauthorizedError,
    Faraday::ForbiddenError, Faraday::UnprocessableContentError
  ]

  def perform(message_id)
    message = Message.find(message_id)
    ticket = message.ticket
    return if message.reply.present?

    ticket.with_lock do
      return reschedule_job(message_id) if ticket.in_progress?

      first_pending_message = pending_messages(ticket).first
      if first_pending_message && first_pending_message.id != message_id
        reschedule_job(5.seconds, first_pending_message.id) # make sure pending messages gets processed
        reschedule_job(message_id)
        return
      end

      ticket.update!(status: :in_progress)
    end

    process_message(message, ticket)
  end

  def reschedule_job(wait = 10.seconds, message_id)
    ProcessSupportMessageJob.set(wait:).perform_later(message_id)
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

  def process_message(message, ticket)
    Ai::SupportAgent.new(message:).call

    ticket.with_lock do
      ticket.update!(status: :waiting_for_customer)
    end
  rescue *NON_RETRIABLE_EXCEPTIONS => e
    Rails.logger.error("Error processing support message: #{e.message}")
    ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    reopen_ticket(ticket)
  rescue StandardError => e
    reopen_ticket(ticket)
    raise e
  end

  def reopen_ticket(ticket)
    ticket&.with_lock do
      ticket.update!(status: :open) if ticket.in_progress?
    end
  end

  def handle_failure(exception)
    message = Message.find(arguments.first)
    ticket = message.ticket
    Rails.logger.error("Error processing support message: #{exception.message}")
    ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    reopen_ticket(ticket)
  end
end
