module ConferenceImportsHelper
  # LLM に渡すプロンプト (指示 + JSON Schema)。末尾に変換したいテキストを貼り付けて使う
  def conference_import_prompt
    <<~PROMPT
      あなたはカンファレンスのタイムテーブルを構造化データに変換するアシスタントです。
      このあと渡すテキスト(公式サイトのタイムテーブル、メモ等)を、下記の JSON Schema に厳密に従う JSON に変換してください。

      ルール:
      - 出力は JSON オブジェクト1つのみ。説明文やコードフェンスは付けない
      - スキーマに無いキーは出力しない
      - 日付は YYYY-MM-DD、日時は ISO 8601 (例: 2026-04-22T10:00:00+09:00) で、現地時間のオフセットを付ける
      - 不明な値は null にするか、キーごと省略する
      - status は特に指示がなければ "planned"
      - tags はセッション内容を表す英小文字の短い単語を 1〜3 個

      JSON Schema:
      #{ConferenceImport.schema_json}
      変換するテキスト:
    PROMPT
  end
end
