module Conferences
  # 聴講メモのエクスポート。重い処理を想定し Solid Queue で非同期実行してメール送信する
  class ExportsController < ApplicationController
    def create
      conference = current_user.conferences.find(params.expect(:conference_id))
      ConferenceExportJob.perform_later(conference)
      redirect_to conference, notice: t(".success", email: current_user.email_address), status: :see_other
    end
  end
end
