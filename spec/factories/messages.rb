FactoryBot.define do
  factory :message do
    association :ticket
    association :user

    role { :customer }
    content { "I was charged twice." }
  end
end
