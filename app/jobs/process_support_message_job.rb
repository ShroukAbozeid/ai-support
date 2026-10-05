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
    job.handle_discard(exception)
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

      message.create_ai_run! if message.ai_run.nil?
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
    message.ai_run.start!
    Ai::SupportAgent.new(message:).call
    finalize_ticket(ticket)
  rescue *NON_RETRIABLE_EXCEPTIONS => exception
    handle_failure(message:, ticket:, exception:)
  rescue StandardError => exception
    message.ai_run.set_error!(error_type: exception.class.name, error_message: exception.message)
    reopen_ticket(ticket)
    raise exception
  end

  def reopen_ticket(ticket)
    ticket&.with_lock do
      ticket.update!(status: :open) if ticket.in_progress?
    end
  end

  def finalize_ticket(ticket)
    ticket.with_lock do
      ticket.update!(status: :waiting_for_customer)
    end
  end

  def handle_failure(message:, ticket:, exception:)
    Rails.logger.error("Error processing support message: #{exception.message}")
    message.ai_run.fail!(error_type: exception.class.name, error_message: exception.message)
    ticket.messages.create!(role: :app, content: "We're sorry, but we encountered an error while processing your request. Please try again later.")
    reopen_ticket(ticket)
  end

  def handle_discard(exception)
    Rails.logger.error("Job discarded due to: #{exception.message}")
    message = Message.find(arguments.first)
    ticket = message.ticket
    handle_failure(message:, ticket:, exception:)
  end
end
