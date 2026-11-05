require "rails_helper"

RSpec.describe "ConferenceImports" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /conference_import/new" do
    it "プロンプトとスキーマを含むページを表示する" do
      get new_conference_import_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("LLM用プロンプトをコピー", "conference_import.schema.json")
    end
  end

  describe "GET /conference_import/schema.json" do
    it "JSON Schema を返す" do
      get schema_conference_import_path(format: :json)
      expect(response.media_type).to eq "application/json"
      expect(response.parsed_body["title"]).to eq "Conference import"
    end

    it "download=1 で添付ファイルとして返す" do
      get schema_conference_import_path(format: :json, download: 1)
      expect(response.headers["Content-Disposition"]).to start_with "attachment"
    end
  end

  describe "POST /conference_import" do
    it "インポートしてカンファレンス詳細へリダイレクトする" do
      json = { name: "Kaigi on Rails 2026", starts_on: "2026-10-01", ends_on: "2026-10-02",
               talks: [{ title: "Rails 8.1", speaker: "someone" }] }.to_json

      expect { post conference_import_path, params: { conference_import: { payload: json } } }
        .to change(user.conferences, :count).by(1)
      expect(response).to redirect_to(conference_path(user.conferences.last))
      follow_redirect!
      expect(response.body).to include("インポートしました(セッション1件)")
    end

    it "不正なら 422 でエラーを表示する" do
      post conference_import_path, params: { conference_import: { payload: "{}" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("スキーマ違反")
    end
  end
end
