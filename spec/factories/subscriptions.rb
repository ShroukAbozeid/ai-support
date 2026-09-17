FactoryBot.define do
  factory :subscription do
    association :user
    plan_name { "Pro" }
    amount { 49.00 }
    currency { "USD" }
    current_period_start { Date.current.beginning_of_month }
    current_period_end { Date.current.end_of_month }
  end
end
