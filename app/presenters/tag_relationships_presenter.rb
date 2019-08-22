# frozen_string_literal: true

class TagRelationshipsPresenter
  attr_reader :following_map, :favourites_map

  def initialize(tags, current_account_id = nil, **options)
    @following_map = begin
      if current_account_id.nil?
        {}
      else
        TagFollow.select(:tag_id).where(tag_id: tags.map(&:id), account_id: current_account_id).each_with_object({}) { |f, h| h[f.tag_id] = true }.merge(options[:following_map] || {})
      end
    end
    @favourites_map = begin
      if current_account_id.nil?
        {}
      else
        FavouriteTag.select(:tag_id).where(tag_id: tags.map(&:id), account_id: current_account_id).each_with_object({}) { |f, h| h[f.tag_id] = true }.merge(options[:favourites_map] || {})
      end
    end
  end
end
