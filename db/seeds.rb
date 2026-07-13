if Rails.env.development?
  require "rake"
  Rails.application.load_tasks unless Rake::Task.task_defined?("db:fixtures:load")
  Rake::Task["db:fixtures:load"].invoke
else
  Tenant.find_or_create_by!(id: 1)
end
