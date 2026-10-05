class AiRun < ApplicationRecord
  belongs_to :message

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, default: :pending


  def complete!
    update!(status: :completed, completed_at: Time.current)
  end

  def start!
    update!(
      status: :processing,
      started_at: started_at || Time.current
    )
  end

  def fail!(error_type: nil, error_message: nil)
    update!(status: :failed, error_type:, error_message:)
  end

  def failed_at
    return unless failed?

    updated_at
  end

  def set_response_id!(response_id)
    update!(open_ai_response_id: response_id)
  end

  def set_conversation_id!(conversation_id)
    return if open_ai_conversation_id.present?

    update!(open_ai_conversation_id: conversation_id)
  end

  def set_error!(error_type:, error_message:)
    update!(error_type:, error_message:)
  end
end
