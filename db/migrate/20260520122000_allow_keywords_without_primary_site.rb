class AllowKeywordsWithoutPrimarySite < ActiveRecord::Migration[8.1]
  def change
    change_column_null :keywords, :site_id, true
  end
end
