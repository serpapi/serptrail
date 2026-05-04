class AddQueryToChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :checks, :query, :string
  end
end
