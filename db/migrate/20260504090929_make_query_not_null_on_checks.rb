class MakeQueryNotNullOnChecks < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      UPDATE checks
      SET query = keywords.query
      FROM keywords
      WHERE checks.keyword_id = keywords.id
        AND checks.query IS NULL
    SQL
    change_column_null :checks, :query, false
  end

  def down
    change_column_null :checks, :query, true
  end
end
