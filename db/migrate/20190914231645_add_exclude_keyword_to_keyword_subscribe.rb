require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddExcludeKeywordToKeywordSubscribe < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured { add_column_with_default :keyword_subscribes, :exclude_keyword, :string, default: '', allow_null: false }
  end

  def down
    remove_column :keyword_subscribes, :exclude_keyword
  end
end
