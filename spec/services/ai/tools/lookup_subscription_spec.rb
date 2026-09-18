require 'rails_helper'

RSpec.describe Ai::Tools::LookupSubscription do
  it "returns only the user's subscription" do
    user = create(:user)
    subscription = create(:subscription, user:)
    other_subscription = create(:subscription)

    expect(described_class.new(user_id: user.id, subscription_id: subscription.id).call)
      .to eq(subscription)
    expect(described_class.new(user_id: user.id, subscription_id: other_subscription.id).call)
      .to be_nil
  end
end
