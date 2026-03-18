class CreateKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :keywords do |t|
      t.references :site, null: false, foreign_key: true
      t.string :query, null: false
      t.string :check_frequency, null: false, default: "daily"
      t.datetime :last_checked_at

      t.timestamps
    end

    add_index :keywords, [ :site_id, :query ], unique: true
  end
end
