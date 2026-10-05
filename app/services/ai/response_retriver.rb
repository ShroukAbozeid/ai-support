module Ai
  class ResponseRetriver
    def initialize(ai_run:)
      @ai_run = ai_run
    end

    def call
      client.responses.retrieve(response_id: ai_run.open_ai_response_id).deep_symbolize_keys
    end

    private

    attr_reader :ai_run

    def client
      @client ||= Ai::Client.new
    end
  end
end
