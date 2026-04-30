class RequireLocationOnChecks < ActiveRecord::Migration[8.0]
  def up
    Check.where(location: nil).delete_all
    change_column_null :checks, :location, false
  end

  def down
    change_column_null :checks, :location, true
  end
end
