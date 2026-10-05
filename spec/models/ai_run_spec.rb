require 'rails_helper'

RSpec.describe AiRun, type: :model do
  describe "associations and status" do
    it "belongs to a message" do
      ai_run = build(:ai_run)

      expect(ai_run.message).to be_present
      expect(ai_run).to be_valid
    end

    it "starts pending with no lifecycle timestamps" do
      ai_run = described_class.new(message: build(:message))

      expect(ai_run).to be_pending
      expect(ai_run.started_at).to be_nil
      expect(ai_run.completed_at).to be_nil
    end
  end

  describe "#start!" do
    it "marks the run as processing and records its first start time" do
      ai_run = create(:ai_run)
      start_time = Time.zone.local(2026, 10, 5, 12)

      allow(Time).to receive(:current).and_return(start_time)
      ai_run.start!

      expect(ai_run.reload).to have_attributes(status: "processing", started_at: start_time)
    end

    it "preserves the original start time when restarted" do
      original_start = 1.hour.ago.change(usec: 0)
      ai_run = create(:ai_run, status: :failed, started_at: original_start)

      ai_run.start!

      expect(ai_run.reload.started_at).to eq(original_start)
    end
  end

  describe "#complete!" do
    it "marks the run completed and records completion time" do
      ai_run = create(:ai_run, status: :processing)
      completion_time = Time.zone.local(2026, 10, 5, 13)

      allow(Time).to receive(:current).and_return(completion_time)
      ai_run.complete!

      expect(ai_run.reload).to have_attributes(
        status: "completed",
        completed_at: completion_time
      )
    end
  end

  describe "#fail!" do
    it "marks the run failed and stores optional error details" do
      ai_run = create(:ai_run, status: :processing)

      ai_run.fail!(error_type: "OpenAI::Error", error_message: "Request failed")

      expect(ai_run.reload).to have_attributes(
        status: "failed",
        error_type: "OpenAI::Error",
        error_message: "Request failed"
      )
      expect(ai_run.failed_at).to eq(ai_run.updated_at)
    end

    it "allows failing without error details" do
      ai_run = create(:ai_run)

      ai_run.fail!

      expect(ai_run.reload).to have_attributes(status: "failed", error_type: nil, error_message: nil)
    end
  end

  describe "#failed_at" do
    it "returns nil unless the run failed" do
      expect(create(:ai_run, status: :processing).failed_at).to be_nil
    end
  end

  describe "response and error setters" do
    let(:ai_run) { create(:ai_run) }

    it "stores the response ID" do
      ai_run.set_response_id!("resp_123")

      expect(ai_run.reload.open_ai_response_id).to eq("resp_123")
    end

    it "stores a conversation ID only when one is not already present" do
      ai_run.set_conversation_id!("conv_first")
      ai_run.set_conversation_id!("conv_second")

      expect(ai_run.reload.open_ai_conversation_id).to eq("conv_first")
    end

    it "stores error details without changing the run status" do
      ai_run.set_error!(error_type: "RuntimeError", error_message: "Unexpected")

      expect(ai_run.reload).to have_attributes(
        status: "pending",
        error_type: "RuntimeError",
        error_message: "Unexpected"
      )
    end
  end
end
