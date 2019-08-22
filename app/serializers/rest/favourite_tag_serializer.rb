# frozen_string_literal: true

class REST::FavouriteTagSerializer < ActiveModel::Serializer
  attributes :name, :updated_at

  def name
    object.display_name
  end
end
