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
class Conference < ApplicationRecord
  belongs_to :user
  has_many :talks, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :starts_on, :ends_on, presence: true
  validate :ends_on_not_before_starts_on
  validate :website_url_must_be_http

  scope :recent_first, -> { order(starts_on: :desc) }

  # このカンファレンスのセッションで使われているタグ
  def used_tags
    Tag.where(id: Tagging.where(talk_id: talks.select(:id)).select(:tag_id)).order(:name)
  end

  private

  def ends_on_not_before_starts_on
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, :before_starts_on) if ends_on < starts_on
  end

  def website_url_must_be_http
    return if website_url.blank?

    uri = URI.parse(website_url)
    errors.add(:website_url, :invalid) unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:website_url, :invalid)
  end
end
