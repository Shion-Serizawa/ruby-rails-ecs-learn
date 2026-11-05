# カンファレンスの聴講メモを Markdown に変換する
class ConferenceMarkdownExporter
  def initialize(conference)
    @conference = conference
  end

  def call
    [header, *talks.map { talk_section(it) }].join("\n")
  end

  private

  attr_reader :conference

  def talks
    conference.talks.includes(:tags).chronological
  end

  def header
    <<~MD
      # #{conference.name}

      - 期間: #{conference.starts_on} 〜 #{conference.ends_on}
      - 会場: #{conference.venue.presence || "-"}
    MD
  end

  def talk_section(talk)
    <<~MD
      ## #{"★ " if talk.favorite?}#{talk.title}

      - スピーカー: #{talk.speaker}
      - ステータス: #{talk.status_label}
      - 評価: #{talk.rating ? ("★" * talk.rating) : "-"}
      - タグ: #{talk.tag_list.presence || "-"}

      #{talk.notes}
    MD
  end
end
