class Subscription < ApplicationRecord
  belongs_to :user
  has_many :invoices, dependent: :nullify

  enum :status, {
    active: "active",
    past_due: "past_due",
    canceled: "canceled"
  }, default: :active

  validates :plan_name, :amount, :currency, :current_period_start, :current_period_end, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :current_period_end, comparison: { greater_than: :current_period_start }
end
