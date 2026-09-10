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

  it "supports ticket categories" do
    ticket = build(:ticket, category: :technical)

    expect(ticket).to be_technical
  end

  it "persists category and human-review classification" do
    ticket = create(
      :ticket,
      category: :billing,
      requires_human: true
    )

    expect(ticket.reload).to have_attributes(
      category: "billing",
      requires_human: true
    )
  end

  it "defaults requires_human to false" do
    expect(create(:ticket).requires_human).to be(false)
  end
end
