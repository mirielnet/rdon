require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddColumnToFollow < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def change
    safety_assured { add_column_with_default :follows, :delivery, :boolean, default: true, allow_null: false  }
  end
end
