module Talks
  # お気に入りのトグル。Turbo Stream でボタン部分だけを差し替える
  class FavoritesController < ApplicationController
    def update
      @talk = Talk.owned_by(current_user).find(params.expect(:talk_id))
      @talk.update!(favorite: !@talk.favorite)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back_or_to @talk, status: :see_other }
      end
    end
  end
end
