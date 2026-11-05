# == Schema Information
#
# Table name: tags
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_tags_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Tag < ApplicationRecord
  belongs_to :user
  has_many :taggings, dependent: :destroy
  has_many :talks, through: :taggings

  normalizes :name, with: ->(name) { name.strip.downcase }

  NAME_MAX_LENGTH = 30

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }, uniqueness: { scope: :user_id }
end
