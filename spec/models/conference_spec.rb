require "rails_helper"

# == Schema Information
#
# Table name: conferences
# Database name: primary
#
#  id          :bigint           not null, primary key
#  ends_on     :date             not null
#  name        :string           not null
#  starts_on   :date             not null
#  talks_count :integer          default(0), not null
#  venue       :string
#  website_url :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_conferences_on_user_id                (user_id)
#  index_conferences_on_user_id_and_starts_on  (user_id,starts_on)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Conference do
  subject(:conference) { build(:conference) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:talks).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:starts_on) }
    it { is_expected.to validate_presence_of(:ends_on) }
    it { is_expected.to allow_value("https://example.com", "", nil).for(:website_url) }
    it { is_expected.not_to allow_value("javascript:alert(1)", "https://", "http://example.com\njavascript:x").for(:website_url) }

    it "終了日が開始日より前だと無効" do
      conference.ends_on = conference.starts_on - 1.day
      expect(conference).not_to be_valid
      expect(conference.errors[:ends_on]).to include "は開始日以降の日付にしてください"
    end
  end

  describe ".recent_first" do
    it "開始日の新しい順に並ぶ" do
      old = create(:conference, starts_on: Date.new(2024, 5, 15), ends_on: Date.new(2024, 5, 17))
      new = create(:conference, starts_on: Date.new(2026, 4, 22), ends_on: Date.new(2026, 4, 24))
      expect(described_class.recent_first).to eq [new, old]
    end
  end
end
