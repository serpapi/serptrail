class RemoveSearchResponseFromChecks < ActiveRecord::Migration[8.1]
  def change
    remove_column :checks, :raw_response, :text
    remove_column :checks, :serpapi_search_id, :string
  end
end
