# frozen_string_literal: true

class Search < ActiveModelSerializers::Model
  attributes :accounts, :statuses, :hashtags, :profiles, :custom_emojis
end
