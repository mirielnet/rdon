require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddColumnToFollowRequest < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def change
    safety_assured { add_column_with_default :follow_requests, :delivery, :boolean, default: true, allow_null: false  }
  end
end
