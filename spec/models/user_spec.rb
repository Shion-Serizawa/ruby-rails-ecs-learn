require "rails_helper"

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
RSpec.describe User do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:conferences).dependent(:destroy) }
    it { is_expected.to have_many(:tags).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).ignoring_case_sensitivity }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.not_to allow_value("invalid").for(:email_address) }
  end

  it "メールアドレスを正規化する" do
    user = described_class.new(email_address: "  Foo@Example.COM ")
    expect(user.email_address).to eq "foo@example.com"
  end
end
