# frozen_string_literal: true

class MisskeySearchabilityUpdateService < BaseService
  def call(account)
    statuses  = account.statuses.where(searchability: [nil, :private], reblog_of_id: nil)

    return unless statuses.exists?

    ids = statuses.pluck(:id)

    statuses.update_all('updated_at = CURRENT_TIMESTAMP')

    return unless Chewy.enabled?

    ids.each_slice(100) do |chunk_ids|
      StatusesIndex.import chunk_ids, update_fields: [:searchability]
    end
  end
end
