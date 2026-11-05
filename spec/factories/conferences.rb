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
FactoryBot.define do
  factory :conference do
    user
    name { "RubyKaigi #{Faker::Number.unique.within(range: 2006..2099)}" }
    venue { Faker::Address.city }
    starts_on { Date.new(2026, 4, 22) }
    ends_on { Date.new(2026, 4, 24) }
    website_url { "https://rubykaigi.org/" }
  end
end
