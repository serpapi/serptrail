class ConvertKeywordLocationToLocations < ActiveRecord::Migration[8.0]
  def up
    add_column :keywords, :locations, :json
    Keyword.reset_column_information
    Keyword.all.each { |k| k.update_column(:locations, [ k.location ]) }
    remove_column :keywords, :location

    add_column :checks, :location, :string
  end

  def down
    add_column :keywords, :location, :string
    Keyword.reset_column_information
    Keyword.all.each { |k| k.update_column(:location, Array(k.locations).first || "us") }
    remove_column :keywords, :locations

    remove_column :checks, :location
  end
end
