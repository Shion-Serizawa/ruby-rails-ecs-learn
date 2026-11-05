class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  # 送信元 IP ごとのリクエスト制限。短時間の連打と、1台から全体上限 (PasswordResetThrottle::GLOBAL_LIMIT) を
  # 使い切られることの両方を防ぐため、短期と長期の2段にする。宛先ごと・全体の送信数の制限は PasswordResetThrottle で行う
  rate_limit to: 10, within: 3.minutes, only: :create, name: "per-ip-burst",
             with: -> { redirect_to new_password_path, alert: t("passwords.create.rate_limited") }
  rate_limit to: 20, within: 1.hour, only: :create, name: "per-ip-hourly",
             with: -> { redirect_to new_password_path, alert: t("passwords.create.rate_limited") }

  def new; end

  def edit; end

  # 登録の有無や制限に引っかかったかどうかで応答を変えない (アカウントの存在を推測させないため)
  def create
    user = User.find_by(email_address: params[:email_address])
    PasswordsMailer.reset(user).deliver_later if user && PasswordResetThrottle.new(user).allow?

    redirect_to new_session_path, notice: t(".success")
  end

  def update
    if @user.update(password_params)
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # 空文字だと has_secure_password が代入を無視して「成功」してしまうため、nil にして必須エラーにする
  def password_params
    attrs = params.permit(:password, :password_confirmation)
    attrs.merge(password: attrs[:password].presence)
  end

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params.expect(:token))
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: t("passwords.invalid_token")
  end
end
