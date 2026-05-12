class AddAiOverviewToChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :checks, :ai_overview_present,           :boolean
    add_column :checks, :ai_overview_cited,             :boolean
    add_column :checks, :ai_overview_citation_position, :integer
    add_column :checks, :raw_response,                  :text
  end
end
