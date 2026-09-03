require 'rails_helper'

RSpec.describe "Messages", type: :request do
  describe "post /create" do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket, user: user) }

    before do
      allow_any_instance_of(ApplicationController)
        .to receive(:current_user)
        .and_return(user)
    end

    it do
      post ticket_messages_path(ticket), params: {
        message: {
          content: "I was charged twice."
        }
      }
     expect(response).to redirect_to(ticket_path(ticket))
    end

    it "enqueues AI processing" do
      expect {
        post ticket_messages_path(ticket), params: {
          message: {
            content: "I was charged twice."
          }
        }
      }.to have_enqueued_job(ProcessSupportMessageJob)
    end
  end
end
