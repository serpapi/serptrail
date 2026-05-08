class RenameToViews < ActiveRecord::Migration[8.1]
  def change
    rename_table :saved_views, :views
    rename_table :saved_view_series, :view_series
    rename_column :view_series, :saved_view_id, :view_id
  end
end
