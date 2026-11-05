require "rails_helper"

RSpec.describe ConferenceMarkdownExporter do
  it "カンファレンスとセッションを Markdown に変換する" do
    conference = create(:conference, name: "RubyKaigi 2026", venue: "函館")
    create(:talk, :attended, :favorite, conference:, title: "Ruby 4.0 の新機能", speaker: "matz")

    markdown = described_class.new(conference).call

    expect(markdown).to include("# RubyKaigi 2026", "会場: 函館", "## ★ Ruby 4.0 の新機能", "スピーカー: matz",
                                "ステータス: 聴講済み", "評価: ★★★★", "とても良かった")
  end
end
