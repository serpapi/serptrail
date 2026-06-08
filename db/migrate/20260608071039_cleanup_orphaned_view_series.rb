class CleanupOrphanedViewSeries < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      DELETE FROM view_series
      WHERE keyword_target_id IS NULL
         OR keyword_target_id NOT IN (SELECT id FROM keyword_targets)
    SQL
  end

  def down
    # irreversible: deleted rows cannot be recovered
  end
end
