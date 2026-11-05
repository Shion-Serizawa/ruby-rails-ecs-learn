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
class Talk < ApplicationRecord
  belongs_to :conference, counter_cache: true
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  enum :status, { planned: 0, attended: 1, skipped: 2 }, default: :planned, validate: true

  validates :title, presence: true, length: { maximum: 200 }
  validates :speaker, presence: true, length: { maximum: 100 }
  validates :rating, numericality: { only_integer: true, in: 1..5 }, allow_nil: true

  before_save :assign_pending_tags

  scope :chronological, -> { order(:starts_at, :id) }
  scope :favorites, -> { where(favorite: true) }
  scope :owned_by, ->(user) { joins(:conference).where(conferences: { user_id: user.id }) }
  # includes(:tags) と併用しても他のタグが欠けないよう、JOIN ではなくサブクエリで絞り込む
  scope :tagged_with, ->(name) { where(id: Tagging.joins(:tag).where(tags: { name: }).select(:talk_id)) }

  def self.filter_by(tag: nil, favorites: false)
    scope = all
    scope = scope.tagged_with(tag) if tag.present?
    scope = scope.favorites if favorites
    scope
  end

  def self.human_status(status)
    I18n.t("activerecord.enums.talk.status.#{status}")
  end

  def status_label
    self.class.human_status(status)
  end

  # "ruby, rails" のようなカンマ区切り文字列でタグを扱う仮想属性
  def tag_list
    (@pending_tag_names || tags.map(&:name)).join(", ")
  end

  # 属性代入の時点では conference が未設定のことがあるため、タグの解決は保存時に行う
  def tag_list=(value)
    @pending_tag_names = value.to_s.split(",").map { it.strip.downcase }.compact_blank.uniq
  end

  private

  def assign_pending_tags
    return if @pending_tag_names.nil?

    owner = conference.user
    self.tags = @pending_tag_names.map { |name| owner.tags.find_or_create_by!(name:) }
    @pending_tag_names = nil
  end
end
