require "rails_helper"

RSpec.describe InvoiceItem, type: :model do
  it { is_expected.to belong_to(:invoice) }

  it "requires a positive quantity and non-negative amounts" do
    item = build(
      :invoice_item,
      quantity: 0,
      unit_amount: -1,
      amount: -1
    )

    expect(item).not_to be_valid
  end
end
