require 'rails_helper'

RSpec.describe Ai::TicketClassifier do
  let(:ticket) { create(:ticket, category: :general, priority: :low) }

  it "updates the ticket classification" do
    response = {
      category: "technical",
      priority: "urgent",
      requires_human: true
    }

    described_class.new(ticket:, response:).call

    expect(ticket.reload).to have_attributes(
      category: "technical",
      priority: "urgent",
      requires_human: true
    )
  end

  it "does not update a ticket when classification is unchanged" do
    ticket.update!(requires_human: false)
    response = {
      category: "general",
      priority: "low",
      requires_human: false
    }

    expect(ticket).not_to receive(:update!)

    described_class.new(ticket:, response:).call
  end
end
