require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddColumnToFollow < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured do
      add_column_with_default :follows, :delivery, :boolean, allow_null: false, default: true
    end
  end

  def down
    remove_column :follows, :delivery
  end
end
