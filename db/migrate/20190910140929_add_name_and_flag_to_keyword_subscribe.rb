require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddNameAndFlagToKeywordSubscribe < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured { add_column_with_default :keyword_subscribes, :name, :string, default: '', allow_null: false }
    safety_assured { add_column_with_default :keyword_subscribes, :ignore_block, :boolean, default: false }
    safety_assured { add_column_with_default :keyword_subscribes, :disabled, :boolean, default: false }
    safety_assured { add_column_with_default :keyword_subscribes, :exclude_home, :boolean, default: false }
  end

  def down
    remove_column :keyword_subscribes, :name
    remove_column :keyword_subscribes, :ignore_block
    remove_column :keyword_subscribes, :disabled
    remove_column :keyword_subscribes, :exclude_home
  end
end
