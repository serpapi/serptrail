if Rails.env.development?
  require "active_record/fixtures"
  ActiveRecord::FixtureSet.reset_cache
  ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("test/fixtures"), %w[sites keywords checks tenants])
else
  Tenant.find_or_create_by!(id: 1) do |t|
    t.serpapi_key = ENV.fetch("SERPAPI_API_KEY", "")
  end
end
