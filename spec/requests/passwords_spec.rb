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

  describe "GET /passwords/:token/edit" do
    it "有効なトークンなら再設定フォームを表示する" do
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:ok)
    end

    it "不正なトークンならリセット要求画面へ戻す" do
      get edit_password_path("invalid-token")
      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to eq "リンクが無効か期限切れです"
    end

    it "期限切れのトークンならリセット要求画面へ戻す" do
      token = user.password_reset_token
      travel 16.minutes do
        get edit_password_path(token)
        expect(response).to redirect_to(new_password_path)
      end
    end
  end

  describe "PUT /passwords/:token" do
    def update_password(token, password, confirmation = password)
      put password_path(token), params: { password:, password_confirmation: confirmation }
    end

    it "パスワードを変更し、既存のセッションをすべて破棄する" do
      user.sessions.create!
      update_password(user.password_reset_token, "new-password-1")

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("new-password-1")).to be_truthy
      expect(user.sessions).to be_empty
    end

    it "変更後は同じトークンを再利用できない" do
      token = user.password_reset_token
      update_password(token, "new-password-1")
      update_password(token, "new-password-2")

      expect(response).to redirect_to(new_password_path)
      expect(user.reload.authenticate("new-password-1")).to be_truthy
    end

    it "確認用と一致しなければ 422 でその理由を表示する" do
      update_password(user.password_reset_token, "new-password-1", "different-1")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("パスワード(確認)")
    end

    it "短すぎれば 422 でその理由を表示する" do
      update_password(user.password_reset_token, "short")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("8文字以上")
    end

    it "空なら変更せず 422 を返す" do
      update_password(user.password_reset_token, "")
      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("password123")).to be_truthy
    end
  end
end
