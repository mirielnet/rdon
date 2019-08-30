require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddSubscribingCountToAccountStat < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured do
      add_column_with_default :account_stats, :subscribing_count, :bigint, allow_null: false, default: 0
    end
  end

  def down
    remove_column :account_stats, :subscribing_count
  end
end
