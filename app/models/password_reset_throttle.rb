# パスワードリセットメールの送信数を制限する。
#
# 「リクエスト数」ではなく「実際に送ったメール数」を数えるのがポイント。
# リクエスト数で数えると、存在しないアドレス宛てのリクエストを連打されるだけで
# 正規ユーザーのリセットまで止められてしまう (DoS)。
#
#   PasswordResetThrottle.new(user).allow? # => true なら送ってよい (同時にカウントする)
#
# カウンタは Rails.cache に置く (本番は Solid Cache なので ECS の複数タスク間で共有される)
class PasswordResetThrottle
  PER_USER_LIMIT = 3
  PER_USER_WINDOW = 1.hour
  GLOBAL_LIMIT = 100
  GLOBAL_WINDOW = 1.hour

  def initialize(user, cache: Rails.cache)
    @user = user
    @cache = cache
  end

  def allow?
    if over_limit?(per_user_key, PER_USER_LIMIT, PER_USER_WINDOW)
      Rails.logger.warn("[PasswordResetThrottle] per-user limit exceeded user_id=#{user.id}")
      false
    elsif over_limit?(global_key, GLOBAL_LIMIT, GLOBAL_WINDOW)
      Rails.logger.warn("[PasswordResetThrottle] global limit exceeded")
      false
    else
      true
    end
  end

  private

  attr_reader :user, :cache

  # increment は原子的なので、同時リクエストでも上限を超えて送られない
  def over_limit?(key, limit, window)
    count = cache.increment(key, 1, expires_in: window)
    count.nil? || count > limit # キャッシュが使えないときは安全側 (送らない) に倒す
  end

  def per_user_key = "password-reset:user:#{user.id}"
  def global_key = "password-reset:global"
end
