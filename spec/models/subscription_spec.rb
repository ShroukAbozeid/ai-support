require "rails_helper"

RSpec.describe Subscription, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:invoices).dependent(:nullify) }

  it "starts active" do
    expect(build(:subscription).status).to eq("active")
  end

  it "requires the billing period to end after it starts" do
    subscription = build(
      :subscription,
      current_period_start: Date.new(2026, 9, 30),
      current_period_end: Date.new(2026, 9, 1)
    )

    expect(subscription).not_to be_valid
  end
end
