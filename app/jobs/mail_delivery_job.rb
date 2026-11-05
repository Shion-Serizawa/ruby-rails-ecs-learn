require "net/smtp"

# deliver_later で使うメール送信ジョブ。SMTP の一時的な失敗 (タイムアウト、4xx 応答等) は間隔を空けて再試行する。
# 認証エラーや宛先不正などの恒久的な失敗は再試行しても無駄なので、そのまま失敗させる (Solid Queue の failed に残る)
class MailDeliveryJob < ActionMailer::MailDeliveryJob
  TRANSIENT_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Net::SMTPServerBusy,
    Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, EOFError
  ].freeze

  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 5)
end
