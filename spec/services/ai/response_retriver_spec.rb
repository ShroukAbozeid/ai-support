require 'rails_helper'

RSpec.describe Ai::ResponseRetriver do
  describe "#call" do
    it "retrieves the stored response and symbolizes its keys" do
      ai_run = create(:ai_run, open_ai_response_id: "resp_saved")
      response = {
        "id" => "resp_saved",
        "output" => [ { "type" => "message" } ]
      }
      responses = instance_double("Responses", retrieve: response)
      client = instance_double("OpenAI::Client", responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)

      result = described_class.new(ai_run:).call

      expect(responses).to have_received(:retrieve).with(response_id: "resp_saved")
      expect(result).to eq(id: "resp_saved", output: [ { type: "message" } ])
    end

    it "propagates retrieval errors so the job can apply its retry policy" do
      ai_run = create(:ai_run, open_ai_response_id: "resp_missing")
      responses = instance_double("Responses")
      allow(responses).to receive(:retrieve).and_raise(Net::ReadTimeout)
      client = instance_double("OpenAI::Client", responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)

      expect { described_class.new(ai_run:).call }.to raise_error(Net::ReadTimeout)
    end
  end
end
