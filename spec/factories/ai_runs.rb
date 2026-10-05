FactoryBot.define do
  factory :ai_run do
    message
    status { :pending }
  end
end
