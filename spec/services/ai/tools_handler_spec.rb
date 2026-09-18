require 'rails_helper'

RSpec.describe Ai::ToolsHandler do
  let(:user) { create(:user) }

  describe "#call" do
    it "dispatches multiple tools with parsed arguments" do
      invoice_result = { status: "paid" }
      subscription_result = { status: "active" }
      invoice_tool = instance_double(Ai::Tools::LookupInvoice, call: invoice_result)
      subscription_tool = instance_double(Ai::Tools::LookupSubscription, call: subscription_result)
      allow(Ai::Tools::LookupInvoice).to receive(:new)
        .with(user_id: user.id, invoice_number: "INV-123")
        .and_return(invoice_tool)
      allow(Ai::Tools::LookupSubscription).to receive(:new)
        .with(user_id: user.id, subscription_id: "sub_123")
        .and_return(subscription_tool)

      tool_calls = [
        {
          name: "lookup_invoice",
          arguments: { invoice_number: "INV-123" }.to_json,
          call_id: "call_invoice"
        },
        {
          name: "lookup_subscription",
          arguments: { subscription_id: "sub_123" }.to_json,
          call_id: "call_subscription"
        }
      ]

      handler = described_class.new(user_id: user.id, tool_calls:)

      handler.call
      expect(handler.messages).to eq([
        {
          type: "function_call_output",
          output: invoice_result.to_json,
          call_id: "call_invoice"
        },
        {
          type: "function_call_output",
          output: subscription_result.to_json,
          call_id: "call_subscription"
        }
      ])
    end

    it "returns an unknown-tool result without dispatching a service" do
      handler = described_class.new(
        user_id: user.id,
        tool_calls: [
          {
            name: "unknown_tool",
            arguments: {}.to_json,
            call_id: "call_unknown"
          }
        ]
      )

      handler.call

      expect(handler.messages).to eq([
        {
          type: "function_call_output",
          output: "Unknown tool: unknown_tool".to_json,
          call_id: "call_unknown"
        }
      ])
    end

    it "raises when tool arguments are invalid JSON" do
      handler = described_class.new(
        user_id: user.id,
        tool_calls: [
          {
            name: "lookup_invoice",
            arguments: "not-json",
            call_id: "call_invalid"
          }
        ]
      )

      expect { handler.call }.to raise_error(JSON::ParserError)
      expect(handler.messages).to be_empty
    end
  end
end
