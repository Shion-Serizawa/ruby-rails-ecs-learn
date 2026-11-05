# Content Security Policy
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# JS は importmap で自前配信のみ、CSS も Tailwind のビルド成果物のみなので、外部オリジンは一切許可しない。
# importmap のインライン <script type="importmap"> と Turbo のプログレスバーの <style> は nonce で許可する
# (Turbo は csp_meta_tag の nonce を読む)。
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.connect_src :self
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  # Turbo のページ遷移と整合させるため、リクエストごとではなくセッション単位の nonce にする。
  # Rails 既定の session.id は初回アクセス (セッション未作成) で空になり、importmap が実行されなくなるので使わない
  config.content_security_policy_nonce_generator = lambda { |request|
    request.session[:csp_nonce] ||= SecureRandom.base64(16)
  }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # letter_opener_web などの開発用ツールを壊さないよう、開発環境では報告のみ (ブラウザのコンソールに出る)
  config.content_security_policy_report_only = Rails.env.development?
end
