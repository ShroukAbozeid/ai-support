class User < ApplicationRecord
  has_many :tickets, dependent: :destroy
  has_many :messages, dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true
  validates :email, uniqueness: true
end
