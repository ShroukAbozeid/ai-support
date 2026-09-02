class ProcessSupportMessageJob < ApplicationJob
  queue_as :default
  retry_on Net::ReadTimeout, wait: 5.seconds, attempts: 3

  def perform(message_id)
    message = Message.find(message_id)
    Ai::SupportAgent.new(message.ticket).call
  end
end
