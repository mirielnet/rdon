# frozen_string_literal: true
# == Schema Information
#
# Table name: account_summaries
#
#  account_id :bigint(8)        primary key
#  language   :string
#  sensitive  :boolean
#

class AccountSummary < ApplicationRecord
  self.primary_key = :account_id

  scope :safe, -> { where(sensitive: false) }
  scope :localized, ->(locale) { where(language: locale) }

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end

  def readonly?
    true
  end
end
