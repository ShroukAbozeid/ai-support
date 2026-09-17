require "rails_helper"

RSpec.describe Invoice, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:subscription).optional }
  it { is_expected.to have_many(:invoice_items).dependent(:destroy) }
  it { is_expected.to have_many(:payments).dependent(:restrict_with_error) }

  it "starts as a draft" do
    expect(build(:invoice).status).to eq("draft")
  end

  it "requires a unique invoice number" do
    create(:invoice, number: "INV-100")

    invoice = build(:invoice, number: "INV-100")

    expect(invoice).not_to be_valid
  end
end
