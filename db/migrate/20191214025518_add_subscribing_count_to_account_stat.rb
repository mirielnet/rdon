require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddSubscribingCountToAccountStat < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def change
    safety_assured { add_column_with_default :account_stats, :subscribing_count, :bigint, default: 0, allow_null: false  }
  end
end
