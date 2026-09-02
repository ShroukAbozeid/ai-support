class Message < ApplicationRecord
  belongs_to :ticket
  belongs_to :user, optional: true

  enum :role, {
    customer: 0,
    agent: 1,
    assistant: 2
  }

  validates :content, presence: true
end
