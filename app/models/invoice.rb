class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :subscription, optional: true

  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :restrict_with_error

  enum :status, {
    draft: "draft",
    open: "open",
    paid: "paid",
    void: "void",
    uncollectible: "uncollectible"
  }, default: :draft

  validates :number, presence: true, uniqueness: true
  validates :currency, :total, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
end
