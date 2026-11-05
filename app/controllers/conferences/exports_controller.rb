module Conferences
  # 聴講メモを Markdown ファイルとしてダウンロードさせる
  class ExportsController < ApplicationController
    # 生成は軽いが、連打やスクリプトからの大量アクセスに備えてユーザー単位で制限する。
    # カウンタは Rails.cache (本番は Solid Cache = DB) に置くので、ECS で複数タスクでも共有される
    rate_limit to: 10, within: 1.minute, by: -> { current_user.id },
               with: lambda {
                 redirect_to conference_path(params[:conference_id]), alert: t(".rate_limited"), status: :see_other
               }

    def show
      conference = current_user.conferences.find(params.expect(:conference_id))
      send_data ConferenceMarkdownExporter.new(conference).call,
                filename: "#{safe_filename(conference.name)}.md",
                type: "text/markdown; charset=utf-8", disposition: :attachment
    end

    private

    # 日本語名をそのまま使う (parameterize は非 ASCII を落とすため)。
    # ファイル名に使えない文字・制御文字だけ置き換える。UTF-8 名は send_data が filename* で送る
    def safe_filename(name)
      name.gsub(%r{[\\/:*?"<>|[:cntrl:]]}, "_").strip.presence || "conference"
    end
  end
end
