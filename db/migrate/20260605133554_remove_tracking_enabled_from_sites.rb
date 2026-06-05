class RemoveTrackingEnabledFromSites < ActiveRecord::Migration[8.1]
  def change
    remove_column :sites, :tracking_enabled, :boolean
  end
end
