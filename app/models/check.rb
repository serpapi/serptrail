class Check < ApplicationRecord
  belongs_to :keyword
  belongs_to :keyword_target, optional: true
  belongs_to :search_run, optional: true

  validates :status, presence: true
  validates :checked_at, presence: true
  validates :location, presence: true
  validates :query, presence: true

  enum :status, { pending: "pending", success: "success", failed: "failed" }

  def query
    search_run&.query || self[:query]
  end

  def location
    search_run&.location || self[:location]
  end

  def checked_at
    search_run&.checked_at || self[:checked_at]
  end

  def serpapi_search_id
    search_run&.serpapi_search_id
  end


  def error_summary
    return nil unless failed? && error_message.present?

    case error_message
    when /500/                             then "Server failed"
    when /out of searches/, /run out/i     then "Search quota exceeded"
    when /invalid api key/i, /api key/i    then "Invalid API key"
    when /no results/i                     then "No results returned"
    when /rate limit/i, /too many/i        then "Rate limit hit"
    when /timeout/i                        then "Request timed out"
    else                                        "Check failed"
    end
  end
end
