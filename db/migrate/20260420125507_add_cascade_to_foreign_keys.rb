class AddCascadeToForeignKeys < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :checks, :keywords
    add_foreign_key :checks, :keywords, on_delete: :cascade

    remove_foreign_key :keywords, :sites
    add_foreign_key :keywords, :sites, on_delete: :cascade
  end

  def down
    remove_foreign_key :checks, :keywords
    add_foreign_key :checks, :keywords

    remove_foreign_key :keywords, :sites
    add_foreign_key :keywords, :sites
  end
end
