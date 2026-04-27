class AddLocationToKeywords < ActiveRecord::Migration[8.0]
  def change
    add_column :keywords, :location, :string, null: false, default: "us"
  end
end
