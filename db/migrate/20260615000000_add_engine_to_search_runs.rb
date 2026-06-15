class AddEngineToSearchRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :search_runs, :engine, :string, null: false, default: "google"
  end
end
