class SerpApiCreditEstimator
  CHECKS_PER_MONTH = {
    "daily" => 30,
    "weekly" => 30.0 / 7,
    "biweekly" => 30.0 / 14,
    "monthly" => 1
  }.freeze

  def initialize(keywords: Keyword.checking_enabled)
    @keywords = keywords
  end

  def monthly_credits
    @monthly_credits ||= keywords.sum do |keyword|
      keyword.search_pages * keyword.locations.size * CHECKS_PER_MONTH.fetch(keyword.check_frequency)
    end.ceil
  end

  def keyword_count
    keywords.size
  end

  private

  attr_reader :keywords
end
