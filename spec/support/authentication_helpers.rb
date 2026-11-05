module AuthenticationHelpers
  module Request
    def sign_in(user, password: "password123")
      post session_path, params: { email_address: user.email_address, password: }
    end
  end

  module System
    def sign_in(user, password: "password123")
      visit new_session_path
      fill_in "メールアドレス", with: user.email_address
      fill_in "パスワード", with: password
      click_button "ログイン"
      expect(page).to have_text(user.email_address)
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers::Request, type: :request
  config.include AuthenticationHelpers::System, type: :system
end
