require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = ENV.fetch("RAILS_ASSUME_SSL", "true") == "true"

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true") == "true"

  # Skip http-to-https redirect for the default health check endpoint.
  # ALB のヘルスチェック(HTTP)がリダイレクトされないよう /up は除外
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger($stdout)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # メール内リンクのホストと差出人は本番で必須。既定値に黙って置き換わると、リセット用トークン入りのリンクが
  # 第三者ドメインを指したり、SES が未検証の差出人を拒否したりするため、未設定なら起動時に KeyError で落とす。
  # イメージビルド中の assets:precompile (SECRET_KEY_BASE_DUMMY=1) だけはダミー値を許す
  required_env = ->(key) { ENV["SECRET_KEY_BASE_DUMMY"] ? ENV.fetch(key, "build.invalid") : ENV.fetch(key) }
  config.action_mailer.default_url_options = {
    host: required_env.call("APP_HOST"),
    protocol: ENV.fetch("APP_PROTOCOL", "https")
  }
  config.action_mailer.default_options = { from: required_env.call("MAILER_FROM") }

  # SMTP (例: Amazon SES の SMTP インターフェース)。接続情報は環境変数で渡す
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS", "localhost"),
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV.fetch("SMTP_USERNAME", nil),
    password: ENV.fetch("SMTP_PASSWORD", nil),
    authentication: ENV["SMTP_USERNAME"].present? ? :plain : nil,
    enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true"
  }.compact

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Host ヘッダの許可リスト (DNS rebinding / Host ヘッダ汚染対策)。カンマ区切りで複数指定可。
  # 未指定なら APP_HOST (メール内リンクのホスト) のホスト名部分を使う
  config.hosts = ENV.fetch("APP_HOSTS") { required_env.call("APP_HOST").split(":").first }
                    .split(",").map(&:strip).compact_blank
  # ALB のヘルスチェックは Host にタスクの IP を入れてくるので /up だけ除外する
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
