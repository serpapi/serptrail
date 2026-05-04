class KeywordCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(keyword, location)
    if Tenant.instance.serpapi_key.blank?
      keyword.checks.create!(
        query: keyword.query,
        status: :failed,
        error_message: "SerpApi key is not configured",
        location: location,
        checked_at: Time.current
      )
      broadcast_keyword_update(keyword)
      return
    end

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
    broadcast_keyword_update(keyword)
  rescue StandardError => e
    keyword.checks.create!(
      query: keyword.query,
      status: :failed,
      error_message: e.message,
      location: location,
      checked_at: Time.current
    )

    broadcast_keyword_update(keyword)
    raise
  end

  private

  def broadcast_keyword_update(keyword)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ keyword.site, :keywords ],
      target: ActionView::RecordIdentifier.dom_id(keyword),
      partial: "keywords/keyword_card",
      locals: { keyword: keyword, site: keyword.site }
    )

    checks_by_location = keyword.checks
      .where(status: "success")
      .order(checked_at: :asc)
      .group_by(&:location)

    location_stats = keyword.locations.map do |loc|
      checks = (checks_by_location[loc] || []).sort_by(&:checked_at).reverse
      latest   = checks.first
      previous = checks.second
      change   = if latest&.position && previous&.position
        previous.position - latest.position
      end
      { location: loc, latest: latest, change: change }
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      keyword,
      target: "keyword_data",
      partial: "keywords/keyword_data",
      locals: {
        keyword: keyword,
        checks_by_location: checks_by_location,
        location_stats: location_stats,
        has_checks: true
      }
    )
  end
end
