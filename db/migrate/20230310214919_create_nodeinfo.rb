class CreateNodeInfo < ActiveRecord::Migration[6.1]
  def change
    create_table :nodeinfos do |t|
      t.string :domain, null: false
      t.jsonb :nodeinfo
      t.jsonb :mastodon_instance
      t.datetime :last_fetched_at, index: true
      t.integer :status, null: false, default: 0
      t.jsonb :override
      t.string :note, null: false, default: ''
      t.attachment :thumbnail
      t.string :blurhash

      t.timestamps
    end

    add_index :nodeinfos, :domain, using: 'hash'
    add_index :nodeinfos, :nodeinfo, using: 'gin'
    add_index :nodeinfos, :mastodon_instance, using: 'gin'
    add_index :nodeinfos, :override, using: 'gin'
  end
end
