FactoryBot.define do
  factory :ticket do
    association :user

    subject { "I was charged twice" }
    status { :open }
    priority { :medium }
    category { nil }
    summary { nil }
  end
end
