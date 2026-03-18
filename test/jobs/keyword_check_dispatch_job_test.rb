require "test_helper"

class KeywordCheckDispatchJobTest < ActiveJob::TestCase
  test "enqueues check jobs for due keywords" do
    assert_enqueued_with(job: KeywordCheckJob) do
      KeywordCheckDispatchJob.perform_now
    end
  end

  test "does not enqueue for disabled sites" do
    # disabled_keyword belongs to disabled site
    enqueued_keywords = []

    perform_enqueued_jobs(only: KeywordCheckDispatchJob) do
      KeywordCheckDispatchJob.perform_now
    end

    assert_enqueued_jobs 0, only: KeywordCheckJob, queue: "default" do
      # only check keywords from enabled sites
      Keyword.due_for_check.each do |kw|
        assert kw.site.tracking_enabled?
      end
    end
  end
end
