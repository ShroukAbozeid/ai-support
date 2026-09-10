require 'rails_helper'

RSpec.describe Ai::ResponseHandler do
  let(:ticket) { create(:ticket, category: :general, priority: :low) }
  let(:message) { create(:message, ticket: ticket) }
  let(:response_text) do
    {
      category: "technical",
      priority: "high",
      requires_human: true,
      message: "I have escalated this issue to our technical support team."
    }.to_json
  end
  let(:open_ai_response) do
    {
      output: [
        {
          type: "message",
          content: [
            { type: "output_text", text: response_text }
          ]
        }
      ]
    }
  end

  describe "#call" do
    it "saves the structured result, updates the ticket, and creates an assistant message" do
      message

      expect do
        described_class.new(
          message: message,
          ticket: ticket,
          open_ai_response: open_ai_response
        ).call
      end.to change(Message, :count).by(1)

      expect(ticket.reload).to have_attributes(
        category: "technical",
        priority: "high",
        requires_human: true
      )
      expect(ticket.messages.last).to have_attributes(
        role: "assistant",
        content: "I have escalated this issue to our technical support team.",
        reply_to_message_id: message.id
      )
    end

    it "rejects a response with missing fields" do
      response = JSON.parse(response_text).except("message").to_json

      expect do
        described_class.new(
          message: message,
          ticket: ticket,
          open_ai_response: response_payload(response)
        ).call
      end.to raise_error(OpenAI::Error, /Missing fields: message/)
    end

    it "rejects invalid category, priority, and requires_human values" do
      {
        category: "accounting",
        priority: "critical",
        requires_human: "yes"
      }.each do |field, value|
        payload = JSON.parse(response_text)
        payload[field.to_s] = value

        expect do
          described_class.new(
            message: message,
            ticket: ticket,
            open_ai_response: response_payload(payload.to_json)
          ).call
        end.to raise_error(OpenAI::Error, /Invalid #{field}/)
      end
    end

    it "raises for invalid JSON" do
      expect do
        described_class.new(
          message: message,
          ticket: ticket,
          open_ai_response: response_payload("not json")
        ).call
      end.to raise_error(JSON::ParserError)
    end

    it "raises when OpenAI refuses the response" do
      refusal = {
        output: [
          {
            type: "message",
            content: [ { type: "refusal", refusal: "I cannot help with that request." } ]
          }
        ]
      }

      expect do
        described_class.new(message:, ticket:, open_ai_response: refusal).call
      end.to raise_error(OpenAI::Error, /Response refused: I cannot help with that request/)
    end

    it "raises when the response is incomplete" do
      incomplete = {
        status: "incomplete",
        incomplete_details: { type: "max_output_tokens" },
        output: []
      }

      expect do
        described_class.new(message:, ticket:, open_ai_response: incomplete).call
      end.to raise_error(OpenAI::Error, /Incomplete response/)
    end
  end

  def response_payload(text)
    {
      output: [
        {
          type: "message",
          content: [ { type: "output_text", text: text } ]
        }
      ]
    }
  end
end