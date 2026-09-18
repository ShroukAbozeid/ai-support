require 'rails_helper'

RSpec.describe Ai::Tools::LookupInvoice do
  it "returns only the user's invoice" do
    user = create(:user)
    invoice = create(:invoice, user:, number: "INV-123")
    create(:invoice, number: "INV-456")

    expect(described_class.new(user_id: user.id, invoice_number: invoice.number).call)
      .to eq(invoice)
  end
end
