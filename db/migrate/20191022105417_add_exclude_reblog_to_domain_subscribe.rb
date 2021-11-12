require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddExcludeReblogToDomainSubscribe < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def change
    safety_assured { add_column_with_default :domain_subscribes, :exclude_reblog, :boolean, default: true }
  end
end
