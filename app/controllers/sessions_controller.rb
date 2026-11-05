class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  # 送信元 IP ごとの制限 (1台からの総当たり対策)
  rate_limit to: 10, within: 3.minutes, only: :create, name: "per-ip",
             with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limited") }
  # 宛先アカウントごとの制限 (多数の IP から1アカウントを狙う総当たり対策)。
  # キャッシュのキーにメールアドレスを平文で残さないようハッシュ化する
  rate_limit to: 20, within: 1.hour, only: :create, name: "per-account",
             by: -> { Digest::SHA256.hexdigest(params[:email_address].to_s.strip.downcase) },
             with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limited") }

  def new; end

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t(".failure")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
