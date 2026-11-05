require "rails_helper"

RSpec.describe "Registrations" do
  describe "POST /registration" do
    it "ユーザーを作成してログイン状態にする" do
      expect do
        post registration_path, params: { user: { email_address: "new@example.com", password: "password123",
                                                  password_confirmation: "password123" } }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(cookies[:session_id]).to be_present
    end

    it "入力が不正なら 422 を返す" do
      post registration_path, params: { user: { email_address: "bad", password: "short", password_confirmation: "x" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
