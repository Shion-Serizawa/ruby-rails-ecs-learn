class ConferenceImportsController < ApplicationController
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
