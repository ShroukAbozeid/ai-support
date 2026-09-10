class Ticket < ApplicationRecord
  belongs_to :user

  has_many :messages, dependent: :destroy
  accepts_nested_attributes_for :messages

  broadcasts_to ->(ticket) { ticket }

  enum :status, {
    open: 0,
    in_progress: 1,
    waiting_for_customer: 2,
    resolved: 3
  }, default: :open

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }, default: :medium

  enum :category, {
    billing: 0,
    technical: 1,
    general: 2
  }, default: :general

  validates :subject, presence: true
  validates :status, presence: true
  validates :priority, presence: true
end
