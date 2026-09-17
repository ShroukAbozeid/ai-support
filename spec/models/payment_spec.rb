require "rails_helper"

RSpec.describe Payment, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:invoice) }

  it "starts pending" do
    expect(build(:payment).status).to eq("pending")
  end

  it "requires a positive amount and unique transaction id" do
    create(:payment, transaction_id: "payment-100")
    payment = build(:payment, amount: 0, transaction_id: "payment-100")

    expect(payment).not_to be_valid
  end
end
