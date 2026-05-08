class CreateSavedViews < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_views do |t|
      t.string :name
      t.integer :s1_keyword_id
      t.string :s1_location
      t.integer :s2_keyword_id
      t.string :s2_location

      t.timestamps
    end
    add_foreign_key :saved_views, :keywords, column: :s1_keyword_id
    add_foreign_key :saved_views, :keywords, column: :s2_keyword_id
  end
end
