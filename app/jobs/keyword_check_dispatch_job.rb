class KeywordCheckDispatchJob < ApplicationJob
  queue_as :default

  def perform
    Keyword.due_for_check.find_each do |keyword|
      keyword.locations.each do |location|
        KeywordCheckJob.perform_later(keyword, location)
      end
    end
  end
end
