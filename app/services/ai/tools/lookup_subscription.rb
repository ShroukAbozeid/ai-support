module Ai
  module Tools
    class LookupSubscription
      def initialize(user_id:, subscription_id:)
        @user_id = user_id
        @subscription_id = subscription_id
      end

      def call
        @subscription = Subscription.find_by(id: subscription_id, user_id:)
      end

      attr_reader :user_id, :subscription_id, :subscription
    end
  end
end
