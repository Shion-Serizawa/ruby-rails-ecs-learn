# 有効期限切れのセッションを削除する (config/recurring.yml から定期実行)
class ExpiredSessionsCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Session.expired.in_batches(of: 1000).delete_all
  end
end
