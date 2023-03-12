# frozen_string_literal: true

# == Schema Information
#
# Table name: nodeinfo_languages
#
#  id          :bigint(8)        not null, primary key
#  nodeinfo_id :bigint(8)        not null
#  language    :string           not null
#  order       :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class NodeInfoLanguage < ApplicationRecord
end
