require 'rails_helper'

RSpec.describe Ticket, type: :model do
   it "starts open" do
    ticket = build(:ticket)

    expect(ticket.status).to eq("open")
  end

  it "supports priorities" do
    ticket = build(:ticket, priority: :urgent)

    expect(ticket).to be_urgent
  end
end
