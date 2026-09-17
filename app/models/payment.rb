class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :invoice

  enum :status, {
    pending: "pending",
    succeeded: "succeeded",
    failed: "failed",
    refunded: "refunded"
  }, default: :pending

  validates :amount, :currency, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :transaction_id, presence: true, uniqueness: true
end
