class ConferenceImportsController < ApplicationController
  # 1回で最大500セッション分の INSERT が走るため、ユーザー単位で制限する
  rate_limit to: 5, within: 1.minute, only: :create, by: -> { current_user.id },
             with: -> { redirect_to new_conference_import_path, alert: t(".rate_limited"), status: :see_other }

  def new
    @import = ConferenceImport.new
  end

  def create
    @import = ConferenceImport.new(user: current_user, **import_params)
    if @import.save
      redirect_to @import.conference, notice: t(".success", count: @import.conference.talks.size)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def import_params
    params.expect(conference_import: [:payload])
  end
end
