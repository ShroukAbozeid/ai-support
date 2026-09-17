FactoryBot.define do
  factory :payment do
    association :user
    association :invoice
    sequence(:transaction_id) { |n| "payment-#{n}" }
    amount { 49.00 }
    currency { "USD" }
  end
end
