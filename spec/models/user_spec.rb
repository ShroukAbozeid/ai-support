require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:tickets).dependent(:destroy) }
  it { is_expected.to have_many(:messages).dependent(:nullify) }

  it "requires a name" do
    user = build(:user, name: nil)

    expect(user).not_to be_valid
  end

  it "requires a unique email" do
    create(:user, email: "customer@example.com")

    user = build(:user, email: "customer@example.com")

    expect(user).not_to be_valid
  end
end
