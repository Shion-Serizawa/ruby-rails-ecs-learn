require "rails_helper"

RSpec.describe "Conferences" do
  let(:user) { create(:user) }
  let(:valid_params) { { conference: { name: "RubyKaigi 2026", starts_on: "2026-04-22", ends_on: "2026-04-24" } } }

  context "未ログインの場合" do
    it "ログイン画面へリダイレクトする" do
      get conferences_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "ログイン済みの場合" do
    before { sign_in user }

    describe "GET /conferences" do
      it "自分のカンファレンスだけを表示する" do
        create(:conference, user:, name: "My Conf")
        create(:conference, name: "Other Conf")

        get conferences_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("My Conf")
        expect(response.body).not_to include("Other Conf")
      end
    end

    describe "GET /conferences/:id" do
      it "他人のカンファレンスは 404" do
        other = create(:conference)
        get conference_path(other)
        expect(response).to have_http_status(:not_found)
      end

      it "タグで絞り込める" do
        conference = create(:conference, user:)
        create(:talk, conference:, title: "Tagged Talk", tag_list: "ruby, hotwire")
        create(:talk, conference:, title: "Plain Talk")

        get conference_path(conference, tag: "ruby")

        expect(response.body).to include("Tagged Talk")
        expect(response.body).not_to include("Plain Talk")
        # 絞り込みに使っていないタグも表示され続けること
        expect(response.body).to include("#hotwire")
      end
    end

    describe "POST /conferences" do
      it "作成して詳細へリダイレクトする" do
        expect { post conferences_path, params: valid_params }.to change(user.conferences, :count).by(1)
        expect(response).to redirect_to(conference_path(Conference.last))
      end

      it "不正な入力なら 422" do
        post conferences_path, params: { conference: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "PATCH /conferences/:id" do
      it "更新する" do
        conference = create(:conference, user:)
        patch conference_path(conference), params: { conference: { name: "Renamed" } }
        expect(conference.reload.name).to eq "Renamed"
      end
    end

    describe "DELETE /conferences/:id" do
      it "削除する" do
        conference = create(:conference, user:)
        expect { delete conference_path(conference) }.to change(Conference, :count).by(-1)
      end
    end

    describe "POST /conferences/:id/export" do
      include ActiveJob::TestHelper

      it "エクスポートジョブをキューに積む" do
        conference = create(:conference, user:)
        expect { post conference_export_path(conference) }
          .to have_enqueued_job(ConferenceExportJob).with(conference)
      end
    end
  end
end
