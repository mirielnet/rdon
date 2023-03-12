class CreateNodeInfoLanguage < ActiveRecord::Migration[6.1]
  def change
    create_table :nodeinfo_languages do |t|
      t.references :nodeinfo, null: false, foreign_key: { on_delete: :cascade }
      t.string :language, null: false
      t.integer :order, null: false, default: 0

      t.timestamps
    end
  end
end
