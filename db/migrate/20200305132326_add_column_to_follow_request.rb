require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddColumnToFollowRequest < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured do
      add_column_with_default :follow_requests, :delivery, :boolean, allow_null: false, default: true
    end
  end

  def down
    remove_column :follow_requests, :delivery
  end
end
