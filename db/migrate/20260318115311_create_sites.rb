class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.boolean :tracking_enabled, null: false, default: true

      t.timestamps
    end

    add_index :sites, :domain, unique: true
  end
end
