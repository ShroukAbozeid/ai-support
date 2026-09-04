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
        "id" => "resp_123",
        "output" => [
          { "type" => "reasoning" },
          {
            "type" => "message",
            "content" => [
              {
                "type" => "output_text",
                "text" => "I'm sorry about that. Let me help."
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

      described_class.new(message: ticket.messages.last).call

      expect(ticket.messages.last).to have_attributes(
        role: "assistant",
        content: "I'm sorry about that. Let me help.",
        open_ai_response_id: "resp_123"
      )
    end

    it "continues an existing response conversation with the new message" do
      ticket = create(:ticket)
      message = create(:message, ticket: ticket, content: "And what about my refund?")
      response = {
        "id" => "resp_456",
        "output" => [
          {
            "type" => "message",
            "content" => [ { "type" => "output_text", "text" => "I can check that." } ]
          }
        ]
      }
      responses = instance_double("Responses", create: response)
      client = instance_double("OpenAI::Client", responses: responses)

      allow(Ai::Client).to receive(:new).and_return(client)

      described_class.new(message:, previous_response_id: "resp_previous").call

      expect(responses).to have_received(:create).with(
        parameters: hash_including(
          model: "gpt-4.1-mini",
          max_output_tokens: 200,
          input: message.content,
          previous_response_id: "resp_previous",
          instructions: kind_of(String)
        )
      )
    end

    it "uses only messages through the current message in the initial prompt" do
      ticket = create(:ticket)
      earlier_message = create(:message, ticket: ticket, content: "Earlier question")
      current_message = create(:message, ticket: ticket, content: "Current question")
      create(:message, ticket: ticket, content: "Later question")
      response = {
        "id" => "resp_prompt",
        "output" => [
          {
            "type" => "message",
            "content" => [ { "type" => "output_text", "text" => "A reply." } ]
          }
        ]
      }
      responses = instance_double("Responses", create: response)
      client = instance_double("OpenAI::Client", responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)

      described_class.new(message: current_message).call

      expect(responses).to have_received(:create).with(
        parameters: hash_including(
          input: include("Earlier question", "Current question")
        )
      )
      expect(responses).not_to have_received(:create).with(
        parameters: hash_including(input: include("Later question"))
      )
      expect(earlier_message).to be_persisted
    end

    it "creates an app message for an OpenAI error" do
      message = create(:message)
      responses = instance_double("Responses")
      allow(responses).to receive(:create).and_raise(OpenAI::Error, "API failed")
      client = instance_double("OpenAI::Client", responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)

      expect { described_class.new(message:).call }.not_to raise_error

      expect(message.ticket.messages.last).to have_attributes(
        role: "app",
        content: include("encountered an error")
      )
    end

    it "propagates timeouts so the job can retry" do
      message = create(:message)
      responses = instance_double("Responses")
      allow(responses).to receive(:create).and_raise(Net::ReadTimeout)
      client = instance_double("OpenAI::Client", responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)

      expect { described_class.new(message:).call }.to raise_error(Net::ReadTimeout)
      expect(message.ticket.messages.where(role: :app)).to be_empty
    end

    it "does not hide assistant message persistence failures" do
      message = create(:message)
      response = {
        "id" => "resp_789",
        "output" => [
          {
            "type" => "message",
            "content" => [ { "type" => "output_text", "text" => "A reply." } ]
          }
        ]
      }
      responses = instance_double("Responses", create: response)
      client = instance_double("OpenAI::Client", responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)
      persistence_error = ActiveRecord::RecordInvalid.new(message)
      allow(message.ticket.messages).to receive(:create!).and_raise(persistence_error)

      expect { described_class.new(message:).call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
