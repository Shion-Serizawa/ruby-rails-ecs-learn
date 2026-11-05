require "rails_helper"

RSpec.describe ConferenceImport do
  subject(:import) { described_class.new(user:, payload: payload.is_a?(String) ? payload : payload.to_json) }

  let(:user) { create(:user) }
  let(:payload) do
    {
      name: "RubyKaigi 2026", venue: "函館", starts_on: "2026-04-22", ends_on: "2026-04-24",
      website_url: "https://rubykaigi.org/2026/",
      talks: [
        { title: "Keynote", speaker: "matz", starts_at: "2026-04-22T10:00:00+09:00", room: "Main",
          tags: %w[ruby keynote], favorite: true },
        { title: "ZJIT", speaker: "k0kubun", starts_at: "2026-04-22T11:00", status: "attended", rating: 5 }
      ]
    }
  end

  describe "JSON Schema" do
    let(:schema) { JSON.parse(described_class.schema_json) }

    it "status の候補が Talk の enum と一致している" do
      enum = schema.dig("properties", "talks", "items", "properties", "status", "enum")
      expect(enum).to match_array(Talk.statuses.keys)
    end

    it "スキーマ自体が JSON Schema として妥当" do
      expect(JSONSchemer.valid_schema?(schema)).to be true
    end
  end

  describe "#save" do
    it "カンファレンスとセッション・タグを一括作成する" do
      expect(import.save).to be true

      conference = import.conference
      expect(conference).to have_attributes(name: "RubyKaigi 2026", user:, talks_count: 2)
      keynote, zjit = conference.talks.chronological
      expect(keynote).to have_attributes(favorite: true, tag_list: "ruby, keynote", status: "planned")
      expect(zjit).to have_attributes(status: "attended", rating: 5)
      # タイムゾーン省略時は日本時間として扱う
      expect(zjit.starts_at).to eq Time.zone.parse("2026-04-22 11:00")
    end

    it "```json のコードフェンス付きでも読み込める" do
      import.payload = "```json\n#{payload.to_json}\n```"
      expect(import.save).to be true
    end

    it "JSON でなければエラー" do
      import.payload = "これはJSONではありません"
      expect(import.save).to be false
      expect(import.errors[:payload]).to include "が正しいJSONオブジェクトではありません"
    end

    it "スキーマ違反は JSON Pointer 付きで報告する" do
      payload[:talks][1][:status] = "unknown"
      payload[:starts_on] = "2026/04/22"

      expect(import.save).to be false
      expect(import.errors.full_messages.join).to include("/talks/1/status", "/starts_on")
    end

    # スキーマでは表現できない制約 (終了日 >= 開始日、URL のホスト有無) はモデル側で検出する
    it "モデルのバリデーション違反も位置付きで報告し、何も保存しない" do
      payload[:ends_on] = "2026-04-01"
      payload[:website_url] = "https://"

      expect { import.save }.not_to change(Conference, :count)
      expect(import.errors.full_messages)
        .to include(a_string_starting_with("/ends_on:"), a_string_starting_with("/website_url:"))
    end
  end
end
