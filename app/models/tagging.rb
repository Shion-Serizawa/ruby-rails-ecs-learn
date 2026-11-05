# == Schema Information
#
# Table name: taggings
# Database name: primary
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tag_id     :bigint           not null
#  talk_id    :bigint           not null
#
# Indexes
#
#  index_taggings_on_tag_id              (tag_id)
#  index_taggings_on_talk_id_and_tag_id  (talk_id,tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => tags.id)
#  fk_rails_...  (talk_id => talks.id)
#
class Tagging < ApplicationRecord
  belongs_to :talk
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :talk_id }
end
