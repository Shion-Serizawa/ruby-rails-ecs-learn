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
      expect(response.headers["Content-Disposition"]).to include("attachment", "rubykaigi-2026.md")
      expect(response.body).to include("# RubyKaigi 2026", "## Keynote")
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
