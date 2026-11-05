require "rails_helper"

RSpec.describe "Talks" do
  let(:user) { create(:user) }
  let(:conference) { create(:conference, user:) }

  before { sign_in user }

  describe "POST /conferences/:conference_id/talks" do
    it "タグ付きで作成する" do
      params = { talk: { title: "Ractor deep dive", speaker: "ko1", status: "attended", rating: 5,
                         tag_list: "ruby, ractor" } }

      expect { post conference_talks_path(conference), params: }.to change(conference.talks, :count).by(1)

      talk = conference.talks.last
      expect(talk.tag_list).to eq "ruby, ractor"
      expect(response).to redirect_to(conference_path(conference))
    end

    it "存在しないステータスなら 422" do
      post conference_talks_path(conference), params: { talk: { title: "x", speaker: "y", status: "unknown" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /talks/:id" do
    it "他人のセッションは 404" do
      get talk_path(create(:talk))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /talks/:id" do
    it "更新する" do
      talk = create(:talk, conference:)
      patch talk_path(talk), params: { talk: { notes: "メモ追記" } }
      expect(talk.reload.notes).to eq "メモ追記"
    end
  end

  describe "DELETE /talks/:id" do
    it "削除してカンファレンスへ戻る" do
      talk = create(:talk, conference:)
      expect { delete talk_path(talk) }.to change(Talk, :count).by(-1)
      expect(response).to redirect_to(conference_path(conference))
    end
  end

  describe "PATCH /talks/:id/favorite" do
    it "Turbo Stream でお気に入りを切り替える" do
      talk = create(:talk, conference:)

      patch talk_favorite_path(talk), as: :turbo_stream

      expect(talk.reload).to be_favorite
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(response.body).to include(%(target="favorite_talk_#{talk.id}"))
    end
  end
end
