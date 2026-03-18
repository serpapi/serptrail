class CreateChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :checks do |t|
      t.references :keyword, null: false, foreign_key: true
      t.integer :position
      t.string :url
      t.string :status, null: false, default: "pending"
      t.string :error_message
      t.datetime :checked_at, null: false

      t.timestamps
    end

    add_index :checks, [ :keyword_id, :checked_at ]
  end
end
