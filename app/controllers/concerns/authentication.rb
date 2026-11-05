module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**)
      skip_before_action(:require_authentication, **)
    end
  end

  private

  def current_user
    Current.user
  end

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    return unless cookies.signed[:session_id]

    Session.active.find_by(id: cookies.signed[:session_id])&.tap do |session|
      next unless session.stale?

      session.refresh!
      write_session_cookie(session)
    end
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      write_session_cookie(session)
    end
  end

  # Cookie の期限もサーバ側の有効期限に揃える (本番では force_ssl により Secure 属性も付く)
  def write_session_cookie(session)
    cookies.signed[:session_id] = { value: session.id, expires: session.expires_at, httponly: true, same_site: :lax }
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
