class Check < ApplicationRecord
  belongs_to :keyword

  validates :status, presence: true
  validates :checked_at, presence: true
  validates :location, presence: true
  validates :query, presence: true

  enum :status, { pending: "pending", success: "success", failed: "failed" }

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
