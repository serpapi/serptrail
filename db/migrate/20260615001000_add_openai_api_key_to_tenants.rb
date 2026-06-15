class AddOpenaiApiKeyToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :openai_api_key, :string, null: false, default: ""
  end
end
