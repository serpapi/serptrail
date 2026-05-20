class AddKeywordTargetsAndSearchRuns < ActiveRecord::Migration[8.1]
  class MigrationKeyword < ActiveRecord::Base
    self.table_name = "keywords"
  end

  class MigrationKeywordTarget < ActiveRecord::Base
    self.table_name = "keyword_targets"
  end

  class MigrationCheck < ActiveRecord::Base
    self.table_name = "checks"
  end

  class MigrationSearchRun < ActiveRecord::Base
    self.table_name = "search_runs"
  end

  def change
    create_table :keyword_targets do |t|
      t.references :keyword, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.boolean :tracking_enabled, null: false, default: true

      t.timestamps
    end

    add_index :keyword_targets, [ :keyword_id, :site_id ], unique: true

    create_table :search_runs do |t|
      t.references :keyword, null: false, foreign_key: true
      t.string :query, null: false
      t.string :location, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :checked_at, null: false
      t.string :serpapi_search_id
      t.json :search_params
      t.text :raw_response
      t.string :error_message

      t.timestamps
    end

    add_index :search_runs, [ :keyword_id, :location, :checked_at ]
    add_index :search_runs, [ :query, :location, :checked_at ]

    add_reference :checks, :keyword_target, foreign_key: true
    add_reference :checks, :search_run, foreign_key: true
    add_index :checks, [ :keyword_target_id, :search_run_id ], unique: true

    add_reference :view_series, :keyword_target, foreign_key: true

    reversible do |dir|
      dir.up do
        backfill_keyword_targets
        backfill_search_runs_and_checks
        backfill_view_series_targets
      end
    end
  end

  private

  def backfill_keyword_targets
    MigrationKeyword.reset_column_information
    MigrationKeywordTarget.reset_column_information

    MigrationKeyword.find_each do |keyword|
      next if keyword.site_id.blank?

      MigrationKeywordTarget.find_or_create_by!(keyword_id: keyword.id, site_id: keyword.site_id)
    end
  end

  def backfill_search_runs_and_checks
    MigrationKeyword.reset_column_information
    MigrationKeywordTarget.reset_column_information
    MigrationCheck.reset_column_information
    MigrationSearchRun.reset_column_information

    MigrationCheck.find_each do |check|
      keyword = MigrationKeyword.find_by(id: check.keyword_id)
      next unless keyword

      target = MigrationKeywordTarget.find_or_create_by!(keyword_id: keyword.id, site_id: keyword.site_id)
      search_run = MigrationSearchRun.create!(
        keyword_id: keyword.id,
        query: check.query.presence || keyword.query,
        location: check.location,
        status: check.status,
        checked_at: check.checked_at,
        serpapi_search_id: check.serpapi_search_id,
        raw_response: check.raw_response,
        error_message: check.error_message
      )

      check.update_columns(keyword_target_id: target.id, search_run_id: search_run.id)
    end
  end

  def backfill_view_series_targets
    return unless table_exists?(:view_series) && column_exists?(:view_series, :keyword_target_id)

    execute <<~SQL.squish
      UPDATE view_series
      SET keyword_target_id = (
        SELECT keyword_targets.id
        FROM keyword_targets
        WHERE keyword_targets.keyword_id = view_series.keyword_id
        LIMIT 1
      )
      WHERE keyword_target_id IS NULL
    SQL
  end
end
