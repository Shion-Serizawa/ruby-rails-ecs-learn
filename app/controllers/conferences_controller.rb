class ConferencesController < ApplicationController
  before_action :set_conference, only: %i[show edit update destroy]

  def index
    @pagy, @conferences = pagy(:offset, current_user.conferences.recent_first, limit: 10)
  end

  def show
    @talks = @conference.talks.includes(:tags).chronological
                        .filter_by(tag: params[:tag], favorites: params[:favorites].present?)
    @tags = @conference.used_tags
  end

  def new
    @conference = current_user.conferences.build(starts_on: Date.current, ends_on: Date.current)
  end

  def edit; end

  def create
    @conference = current_user.conferences.build(conference_params)
    if @conference.save
      redirect_to @conference, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @conference.update(conference_params)
      redirect_to @conference, notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @conference.destroy!
    redirect_to conferences_path, notice: t(".success"), status: :see_other
  end

  private

  def set_conference
    @conference = current_user.conferences.find(params.expect(:id))
  end

  def conference_params
    params.expect(conference: %i[name venue starts_on ends_on website_url])
  end
end
