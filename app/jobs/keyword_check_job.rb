class KeywordCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(keyword, location)
    client = SerpApiClient.new
    result = client.check_position(keyword.query, keyword.site.domain, location: location)

    keyword.checks.create!(
      query: keyword.query,
      position: result[:position],
      url: result[:url],
      serpapi_search_id: result[:serpapi_search_id],
      location: location,
      status: :success,
      checked_at: Time.current
    )

    keyword.update!(last_checked_at: Time.current)
  rescue StandardError => e
    keyword.checks.create!(
      query: keyword.query,
      status: :failed,
      error_message: e.message,
      location: location,
      checked_at: Time.current
    )

    raise
  end
end
