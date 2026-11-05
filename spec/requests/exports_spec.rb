require "rails_helper"

RSpec.describe "Exports" do
  let(:user) { create(:user) }
  let(:conference) { create(:conference, user:, name: "RubyKaigi 2026") }

  before { sign_in user }

  describe "GET /conferences/:id/export" do
    it "Markdown ファイルとしてダウンロードさせる" do
      create(:talk, conference:, title: "Keynote")

      get conference_export_path(conference)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "text/markdown"
      expect(response.headers["Content-Disposition"]).to include("attachment", "RubyKaigi%202026.md")
      expect(response.body).to include("# RubyKaigi 2026", "## Keynote")
    end

    it "日本語のカンファレンス名をファイル名に残し、使えない文字は置き換える" do
      conference.update!(name: "松江Ruby会議/2026")

      get conference_export_path(conference)

      filename = response.headers["Content-Disposition"][/filename\*=UTF-8''(.+)\z/, 1]
      expect(CGI.unescape(filename)).to eq "松江Ruby会議_2026.md"
    end

    it "他人のカンファレンスは 404" do
      get conference_export_path(create(:conference))
      expect(response).to have_http_status(:not_found)
    end

    it "1分に10回を超えるとリダイレクトして案内する" do
      10.times { get conference_export_path(conference) }
      expect(response).to have_http_status(:ok)

      get conference_export_path(conference)

      expect(response).to redirect_to(conference_path(conference))
      expect(flash[:alert]).to include("回数が多すぎます")
    end
  end
end
