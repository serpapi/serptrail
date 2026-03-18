require "active_record/fixtures"

ActiveRecord::FixtureSet.reset_cache
ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("test/fixtures"), %w[sites keywords checks])
