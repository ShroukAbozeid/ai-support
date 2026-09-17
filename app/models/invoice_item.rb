class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validates :description, :quantity, :unit_amount, :amount, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_amount, :amount, numericality: { greater_than_or_equal_to: 0 }
end
