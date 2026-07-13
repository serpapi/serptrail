class AddSearchRunPages < ActiveRecord::Migration[8.1]
  class MigrationSearchRun < ActiveRecord::Base
    self.table_name = "search_runs"
  end

  class MigrationSearchRunPage < ActiveRecord::Base
    self.table_name = "search_run_pages"
  end

  def up
    add_column :keywords, :search_pages, :integer, null: false, default: 1
    add_column :search_runs, :requested_pages, :integer, null: false, default: 1

    create_table :search_run_pages do |t|
      t.references :search_run, null: false, foreign_key: true
      t.integer :page_number, null: false
      t.integer :start, null: false
      t.string :status, null: false, default: "pending"
      t.string :serpapi_search_id
      t.json :search_params
      t.text :raw_response
      t.string :error_message

      t.timestamps
    end

    add_index :search_run_pages, [ :search_run_id, :page_number ], unique: true

    MigrationSearchRun.reset_column_information
    MigrationSearchRunPage.reset_column_information

    MigrationSearchRun.find_each do |search_run|
      MigrationSearchRunPage.create!(
        search_run_id: search_run.id,
        page_number: 1,
        start: 0,
        status: search_run.status,
        serpapi_search_id: search_run.serpapi_search_id,
        search_params: search_run.search_params,
        raw_response: search_run.raw_response,
        error_message: search_run.error_message,
        created_at: search_run.created_at,
        updated_at: search_run.updated_at
      )
    end
  end

  def down
    drop_table :search_run_pages
    remove_column :search_runs, :requested_pages
    remove_column :keywords, :search_pages
  end
end
