class AddMatchSubdomainsToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :match_subdomains, :boolean, default: false, null: false
  end
end
