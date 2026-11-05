require "rails_helper"

RSpec.describe "カンファレンスの聴講メモ" do
  it "新規登録してカンファレンスとセッションを記録できる" do
    visit new_registration_path
    fill_in "メールアドレス", with: "rubyist@example.com"
    fill_in "パスワード", with: "password123"
    fill_in "パスワード(確認)", with: "password123"
    click_button "登録する"
    expect(page).to have_text "アカウントを作成しました"

    click_on "カンファレンスを追加"
    fill_in "名前", with: "RubyKaigi 2026"
    fill_in "会場", with: "函館"
    click_button "登録する"
    expect(page).to have_text "カンファレンスを登録しました"

    click_on "セッションを追加"
    fill_in "タイトル", with: "Ruby 4.0 の新機能"
    fill_in "スピーカー", with: "matz"
    fill_in "タグ(カンマ区切り)", with: "ruby, keynote"
    click_button "登録する"

    expect(page).to have_text "セッションを登録しました"
    expect(page).to have_text "Ruby 4.0 の新機能"
    expect(page).to have_link "#keynote"
  end

  context "JavaScript が動く環境", :js do
    let(:user) { create(:user) }
    let!(:talk) { create(:talk, conference: create(:conference, user:), title: "Hotwire talk") }

    it "お気に入りをページ遷移なしで切り替えられる" do
      sign_in user
      visit conference_path(talk.conference)

      within "#favorite_talk_#{talk.id}" do
        click_button "★"
        expect(page).to have_css("button[aria-pressed='true']")
      end
      expect(talk.reload).to be_favorite
    end

    it "メモの文字数が表示される" do
      sign_in user
      visit edit_talk_path(talk)
      fill_in "メモ", with: "こんにちは"
      expect(page).to have_text "5 文字"
    end
  end
end
