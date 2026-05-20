namespace :checks do
  desc "Repair legacy checks and create missing checks from stored SearchRun responses"
  task backfill_missing: :environment do
    MissingChecksBackfillJob.perform_now
    puts "Missing checks backfill finished."
  end
end
