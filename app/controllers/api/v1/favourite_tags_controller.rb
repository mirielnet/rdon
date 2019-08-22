# frozen_string_literal: true

class Api::V1::FavouriteTagsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:accounts' }, only: :index

  before_action :require_user!
  before_action :set_favourite_tags, only: :index

  def index
    render json: @favourite_tags, each_serializer: REST::FavouriteTagSerializer
  end

  private

  def set_favourite_tags
    @favourite_tags = current_account.favourite_tags
  end
end
