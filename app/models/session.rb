# == Schema Information
#
# Table name: sessions
# Database name: primary
#
#  id         :bigint           not null, primary key
#  ip_address :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Session < ApplicationRecord
  # 最後のアクセスからこの期間が過ぎたセッションは無効 (アクセスのたびに延長するスライディング方式)
  TTL = 30.days
  # 毎リクエストで UPDATE しないよう、延長はこの間隔ごとにまとめる
  REFRESH_INTERVAL = 1.hour

  belongs_to :user

  scope :active, -> { where(updated_at: TTL.ago..) }
  scope :expired, -> { where(updated_at: ...TTL.ago) }

  def expires_at = updated_at + TTL

  # 前回の延長から REFRESH_INTERVAL 以上経っているか
  def stale? = updated_at <= REFRESH_INTERVAL.ago

  # 最終アクセスを記録して有効期限を延ばす
  def refresh! = update!(updated_at: Time.current)
end
