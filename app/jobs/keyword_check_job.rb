class KeywordCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(keyword)
    client = SerpApiClient.new
    result = client.check_position(keyword.query, keyword.site.domain, location: keyword.location)

    keyword.checks.create!(
      position: result[:position],
      url: result[:url],
      serpapi_search_id: result[:serpapi_search_id],
      status: :success,
      checked_at: Time.current
    )

    keyword.update!(last_checked_at: Time.current)
  rescue StandardError => e
    keyword.checks.create!(
      status: :failed,
      error_message: e.message,
      checked_at: Time.current
    )

    raise
  end
end
