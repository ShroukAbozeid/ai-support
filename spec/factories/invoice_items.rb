FactoryBot.define do
  factory :invoice_item do
    association :invoice
    description { "Pro subscription" }
    quantity { 1 }
    unit_amount { 49.00 }
    amount { 49.00 }
  end
end
