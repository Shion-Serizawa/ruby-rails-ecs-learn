require "rails_helper"

RSpec.describe "Sessions" do
  let(:user) { create(:user) }

  def sign_in_from(ip, password: "password123")
    post session_path, params: { email_address: user.email_address, password: },
                       headers: { "REMOTE_ADDR" => ip }
  end

  describe "POST /session" do
    it "正しい認証情報ならログインする" do
      sign_in user
      expect(response).to redirect_to(root_url)
      expect(user.sessions.count).to eq 1
    end

    it "同じアカウントへの試行は IP が違っても1時間に20回までに制限する" do
      20.times { |i| sign_in_from("203.0.113.#{i}", password: "wrong") }

      sign_in_from("198.51.100.1")

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq "しばらく時間をおいてから再度お試しください"
      expect(user.sessions).to be_empty
    end
  end

  describe "セッションの有効期限" do
    before { sign_in user }

    let(:session_record) { user.sessions.sole }

    it "最終アクセスから30日を過ぎたセッションは無効になる" do
      session_record.update!(updated_at: 31.days.ago)

      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "アクセスするたびに有効期限が延びる" do
      session_record.update!(updated_at: 2.hours.ago)

      get root_path
      expect(response).to have_http_status(:ok)
      expect(session_record.reload.updated_at).to be_within(1.minute).of(Time.current)
    end
  end
end
