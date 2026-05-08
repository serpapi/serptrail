class RefactorSavedViewsToUseSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_view_series do |t|
      t.references :saved_view, null: false, foreign_key: true
      t.references :keyword,    null: false, foreign_key: true
      t.string     :location,   null: false
      t.integer    :position,   null: false, default: 0

      t.timestamps
    end

    remove_foreign_key :saved_views, column: :s1_keyword_id
    remove_foreign_key :saved_views, column: :s2_keyword_id
    remove_column :saved_views, :s1_keyword_id, :integer
    remove_column :saved_views, :s1_location,   :string
    remove_column :saved_views, :s2_keyword_id, :integer
    remove_column :saved_views, :s2_location,   :string
  end
end
