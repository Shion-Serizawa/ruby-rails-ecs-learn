require "rails_helper"

RSpec.describe "Passwords" do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  def request_reset(email)
    post passwords_path, params: { email_address: email }
  end

  describe "POST /passwords" do
    it "登録済みのアドレスにリセットメールを送る" do
      expect { request_reset(user.email_address) }
        .to have_enqueued_mail(PasswordsMailer, :reset).with(user)
      expect(response).to redirect_to(new_session_path)
    end

    it "未登録のアドレスでも同じ応答を返し、メールは送らない" do
      expect { request_reset("nobody@example.com") }.not_to have_enqueued_mail
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq "パスワードリセットの案内を送信しました(登録済みの場合)"
    end

    it "同じ宛先へは1時間に3通までで、超えても応答は変えない" do
      3.times { request_reset(user.email_address) }

      expect { request_reset(user.email_address) }.not_to have_enqueued_mail
      expect(flash[:notice]).to eq "パスワードリセットの案内を送信しました(登録済みの場合)"
    end

    it "同じ IP からは3分に10回までに制限する" do
      10.times { |i| request_reset("someone#{i}@example.com") }

      request_reset("someone@example.com")

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to eq "しばらく時間をおいてから再度お試しください"
    end
  end
end
