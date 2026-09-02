require 'rails_helper'

RSpec.describe Message, type: :model do
   it "requires content" do
    message = build(:message, content: nil)

    expect(message).not_to be_valid
  end

  it "supports assistant messages without a user" do
    message = build(
      :message,
      user: nil,
      role: :assistant
    )

    expect(message).to be_valid
  end
end
