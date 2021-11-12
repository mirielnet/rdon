class RenameStatusesIndexExcludeExpires < ActiveRecord::Migration[6.1]
  def up
    rename_index :statuses, :index_statuses_20210710, :index_statuses_20190820 if index_exists?(:statuses, [:account_id, :id, :visibility, :updated_at], name: :index_statuses_20210710)
  end

  def down
    rename_index :statuses, :index_statuses_20190820, :index_statuses_20210710
  end
end
