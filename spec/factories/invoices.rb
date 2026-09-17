FactoryBot.define do
  factory :invoice do
    association :user
    sequence(:number) { |n| "INV-#{n}" }
    currency { "USD" }
    subtotal { 49.00 }
    total { 49.00 }
  end
end
