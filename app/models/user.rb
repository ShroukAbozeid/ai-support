class User < ApplicationRecord
  has_many :tickets, dependent: :destroy
  has_many :messages, dependent: :nullify
  has_many :subscriptions, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true
  validates :email, uniqueness: true
end
