require 'rails_helper'
RSpec.describe Ai::SupportAgent do
  describe "#call" do
    it "creates an assistant message" do
      ticket = create(:ticket)

      ticket.messages.create!(
        user: ticket.user,
        role: :customer,
        content: "I was charged twice."
      )

      response = {
        "output": [
          { "type": "reasoning" },
          {
            "type": "message",
            "content": [
              {
                "text": "I'm sorry about that. Let me help."
              }
            ]
          }
        ]
      }

      client = instance_double("OpenAI::Client")

      allow(Ai::Client)
        .to receive(:new)
        .and_return(client)

      allow(client)
        .to receive(:responses)
        .and_return(
          instance_double(
            "Responses",
            create: response
          )
        )

      described_class.new(ticket).call

      expect(ticket.messages.last).to have_attributes(
        role: "assistant",
        content: "I'm sorry about that. Let me help."
      )
    end
  end
end
