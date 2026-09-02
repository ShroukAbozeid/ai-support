require 'rails_helper'

RSpec.describe "Tickets", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/tickets"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      ticket = create(:ticket)
      get "/tickets/#{ticket.id}"
      expect(response).to have_http_status(:success)
    end

    it "does not allow access to another user's ticket" do
      user = create(:user)
      other_user = create(:user)

      ticket = create(:ticket, user: other_user)

      allow_any_instance_of(ApplicationController)
        .to receive(:current_user)
        .and_return(user)

      get ticket_path(ticket)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/tickets/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /tickets" do
    it "creates a ticket" do
      user = create(:user)

      allow_any_instance_of(ApplicationController)
        .to receive(:current_user)
        .and_return(user)

      expect {
        post tickets_path, params: {
          ticket: {
            subject: "Duplicate charge",
            message: "I was charged twice."
          }
        }
      }.to change(Ticket, :count).by(1)

      ticket = Ticket.last

      expect(ticket.subject).to eq("Duplicate charge")
      expect(ticket.messages.count).to eq(1)
      expect(ticket.messages.first.role).to eq("customer")
    end
  end
end
