class TalksController < ApplicationController
  before_action :set_conference, only: %i[new create]
  before_action :set_talk, only: %i[show edit update destroy]

  def show; end

  def new
    @talk = @conference.talks.build
  end

  def edit; end

  def create
    @talk = @conference.talks.build(talk_params)
    if @talk.save
      redirect_to @conference, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @talk.update(talk_params)
      redirect_to @talk, notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @talk.destroy!
    redirect_to @talk.conference, notice: t(".success"), status: :see_other
  end

  private

  def set_conference
    @conference = current_user.conferences.find(params.expect(:conference_id))
  end

  def set_talk
    @talk = Talk.owned_by(current_user).find(params.expect(:id))
    @conference = @talk.conference
  end

  def talk_params
    params.expect(talk: %i[title speaker starts_at room status rating notes favorite tag_list])
  end
end
