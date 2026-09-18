require 'rails_helper'

RSpec.describe Ai::Tools::EscalateToHuman do
  it "marks the user's ticket as requiring human support" do
    user = create(:user)
    ticket = create(:ticket, user:, requires_human: false)

    described_class.new(user_id: user.id, ticket_id: ticket.id).call

    expect(ticket.reload).to be_requires_human
  end

  it "does not escalate another user's ticket" do
    user = create(:user)
    ticket = create(:ticket, requires_human: false)

    expect do
      described_class.new(user_id: user.id, ticket_id: ticket.id).call
    end.to raise_error(ActiveRecord::RecordNotFound)
    expect(ticket.reload).not_to be_requires_human
  end
end
