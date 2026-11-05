class ConferenceImportsController < ApplicationController
  def new
    @import = ConferenceImport.new
  end

  # GET /conference_import/schema(.json) — JSON Schema をそのまま返す (ダウンロード/外部ツール連携用)
  def schema
    send_data ConferenceImport.schema_json, type: :json, disposition: params[:download] ? "attachment" : "inline",
                                            filename: "conference_import.schema.json"
  end

  def create
    @import = ConferenceImport.new(user: current_user, payload: params.dig(:conference_import, :payload))
    if @import.save
      redirect_to @import.conference, notice: t(".success", count: @import.conference.talks.size)
    else
      render :new, status: :unprocessable_content
    end
  end
end
