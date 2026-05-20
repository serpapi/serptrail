namespace :checks do
  desc "Create missing checks from stored SearchRun responses"
  task backfill_missing: :environment do
    MissingChecksBackfillJob.perform_now
    puts "Missing checks backfill finished."
  end
end
