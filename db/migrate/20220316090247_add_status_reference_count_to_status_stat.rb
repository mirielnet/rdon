require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddStatusReferenceCountToStatusStat < ActiveRecord::Migration[6.1]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured { add_column_with_default :status_stats, :status_references_count, :bigint, default: 0, allow_null: false }
    safety_assured { add_column_with_default :status_stats, :status_referred_by_count, :bigint, default: 0, allow_null: false }
  end

  def down
    remove_column :status_stats, :status_referred_by_count
    remove_column :status_stats, :status_references_count
  end
end
