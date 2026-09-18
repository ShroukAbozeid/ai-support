module Ai
  class ToolsHandler
    attr_reader :messages

    def initialize(user_id:, tool_calls:)
      @user_id = user_id
      @tool_calls = tool_calls
      @messages = []
    end

    def call
      @tool_calls.each do |tool_call|
        tool_call_id = tool_call[:call_id]
        tool_name = tool_call[:name]
        tool_params = JSON.parse(tool_call[:arguments], symbolize_names: true)

        result = execute_tool(tool_name, tool_params)
        @messages << {
          type: 'function_call_output',
          output: result.to_json,
          call_id: tool_call_id
        }
      end
    end

    private

    attr_reader :user_id, :tool_calls

    def execute_tool(tool_name, tool_params)
       case tool_name
       when "lookup_invoice"
          Tools::LookupInvoice.new(user_id:, **tool_params).call
       when "lookup_subscription"
          Tools::LookupSubscription.new(user_id:, **tool_params).call
       when "escalate_to_human"
          Tools::EscalateToHuman.new(user_id:, **tool_params).call
       else
          "Unknown tool: #{tool_name}"
       end
    end
  end
end
