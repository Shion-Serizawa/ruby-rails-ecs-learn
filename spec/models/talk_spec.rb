require "rails_helper"

# == Schema Information
#
# Table name: talks
# Database name: primary
#
#  id            :bigint           not null, primary key
#  favorite      :boolean          default(FALSE), not null
#  notes         :text
#  rating        :integer
#  room          :string
#  speaker       :string           not null
#  starts_at     :datetime
#  status        :integer          default("planned"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  conference_id :bigint           not null
#
# Indexes
#
#  index_talks_on_conference_id                (conference_id)
#  index_talks_on_conference_id_and_starts_at  (conference_id,starts_at)
#
# Foreign Keys
#
#  fk_rails_...  (conference_id => conferences.id)
#
RSpec.describe Talk do
  subject(:talk) { build(:talk) }

  describe "associations" do
    it { is_expected.to belong_to(:conference).counter_cache(true) }
    it { is_expected.to have_many(:tags).through(:taggings) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:speaker) }
    it { is_expected.to validate_numericality_of(:rating).only_integer.is_in(1..5).allow_nil }
    it { is_expected.to define_enum_for(:status).with_values(planned: 0, attended: 1, skipped: 2).validating }
  end

  describe "#tag_list=" do
    it "カンマ区切りの文字列からタグを作成・再利用する" do
      existing = create(:tag, user: talk.conference.user, name: "ruby")
      talk.tag_list = " Ruby, performance ,, ruby "
      talk.save!

      expect(talk.tags.map(&:name)).to contain_exactly("ruby", "performance")
      expect(talk.tags).to include existing
      expect(talk.tag_list).to eq "ruby, performance"
    end
  end

  describe ".owned_by" do
    it "指定ユーザーのカンファレンスに属するセッションだけを返す" do
      mine = create(:talk)
      create(:talk)
      expect(described_class.owned_by(mine.conference.user)).to eq [mine]
    end
  end

  describe "#status_label" do
    it { expect(build(:talk, :attended).status_label).to eq "聴講済み" }
  end
end
