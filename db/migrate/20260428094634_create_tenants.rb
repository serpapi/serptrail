class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :serpapi_key, null: false, default: ""
      t.timestamps
    end
  end
end
