module ConferenceImports
  # GET /conference_import/schema(.json) — インポート用の JSON Schema を返す (ダウンロード/外部ツール連携用)
  class SchemasController < ApplicationController
    def show
      send_data ConferenceImport.schema_json, type: :json, disposition: params[:download] ? "attachment" : "inline",
                                              filename: "conference_import.schema.json"
    end
  end
end
