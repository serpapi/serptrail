class AddSerpapiSearchIdToChecks < ActiveRecord::Migration[8.0]
  def change
    add_column :checks, :serpapi_search_id, :string
  end
end
