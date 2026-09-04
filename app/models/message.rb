class Message < ApplicationRecord
  belongs_to :ticket
  belongs_to :user, optional: true
  belongs_to :reply_to_message, class_name: "Message", optional: true

  after_create_commit -> { broadcast_append_to ticket }

  enum :role, {
    customer: 0, # User
    agent: 1, # Human agent
    assistant: 2, # AI assistant
    app: 3 # Backend
  }

  validates :content, presence: true
end
