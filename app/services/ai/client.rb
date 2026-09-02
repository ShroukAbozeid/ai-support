module Ai
  class Client
    def initialize
       @client = OpenAI::Client.new(
        access_token: ENV.fetch("OPENAI_KEY"),
        log_errors: true
      )
    end

    def responses
      @client.responses
    end
  end
end
