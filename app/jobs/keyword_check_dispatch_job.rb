class KeywordCheckDispatchJob < ApplicationJob
  queue_as :default

  def perform
    Keyword.due_for_check.find_each do |keyword|
      KeywordCheckJob.perform_later(keyword)
    end
  end
end
