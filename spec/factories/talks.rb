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
FactoryBot.define do
  factory :talk do
    conference
    title { Faker::Lorem.sentence(word_count: 4) }
    speaker { Faker::Name.name }
    starts_at { Time.zone.parse("2026-04-22 10:00") }
    room { "Main Hall" }
    status { :planned }

    trait :attended do
      status { :attended }
      rating { 4 }
      notes { "とても良かった" }
    end

    trait :favorite do
      favorite { true }
    end
  end
end
