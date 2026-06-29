class KeywordCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(keyword, location)
    checked_at = Time.current
    targets = keyword_targets_for(keyword)

    search_run = keyword.search_runs.create!(
      query: keyword.query,
      location: location,
      status: :pending,
      checked_at: checked_at
    )

    if Tenant.instance.serpapi_key.blank?
      search_run.update!(status: :failed, error_message: "SerpApi key is not configured")
      create_failed_checks(keyword, targets, search_run, "SerpApi key is not configured")
      broadcast_keyword_updates(targets)
      return
    end

    client = SerpApiClient.new
    results = client.search(keyword.query, location: location)

    search_run.update!(
      status: :success,
      serpapi_search_id: results.dig(:search_metadata, :id),
      raw_response: results.to_json
    )

    targets.each do |target|
      result = client.extract_position(results, target.site.domain, match_subdomains: target.site.match_subdomains)
      create_check(keyword, target, search_run, result.merge(status: :success))
    end

    keyword.update!(last_checked_at: checked_at)
    broadcast_keyword_updates(targets)
    Turbo::StreamsChannel.broadcast_refresh_to(keyword)
  rescue StandardError => e
    search_run ||= keyword.search_runs.create!(
      query: keyword.query,
      location: location,
      status: :failed,
      error_message: e.message,
      checked_at: Time.current
    )
    search_run.update!(status: :failed, error_message: e.message) unless search_run.failed?

    targets ||= keyword_targets_for(keyword)
    create_failed_checks(keyword, targets, search_run, e.message)
    broadcast_keyword_updates(targets)
    raise
  end

  private

  def keyword_targets_for(keyword)
    keyword.keyword_targets.includes(:site).merge(KeywordTarget.tracked).to_a
  end

  def create_failed_checks(keyword, targets, search_run, message)
    targets.each do |target|
      next if target.checks.exists?(search_run: search_run)

      create_check(keyword, target, search_run, status: :failed, error_message: message)
    end
  end

  def create_check(keyword, target, search_run, attributes)
    check = target.checks.find_or_initialize_by(search_run: search_run)
    check.assign_attributes(
      {
        keyword: keyword,
        query: search_run.query,
        location: search_run.location,
        checked_at: search_run.checked_at,
        status: attributes[:status]
      }.merge(attributes.except(:status))
    )
    check.save!
  end

  def broadcast_keyword_updates(targets)
    targets.each { |target| broadcast_keyword_update(target) }
  end

  def broadcast_keyword_update(target)
    keyword = target.keyword

    Turbo::StreamsChannel.broadcast_replace_to(
      [ target.site, :keywords ],
      target: ActionView::RecordIdentifier.dom_id(target),
      partial: "sites/keywords/keyword_card",
      locals: { keyword_target: target, keyword: keyword, site: target.site }
    )

    checks_by_location = target.checks
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
      latest_ai = checks.find { |c| !c.ai_overview_present.nil? }
      { location: loc, latest: latest, change: change, latest_ai: latest_ai }
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      target,
      target: "keyword_data",
      partial: "sites/keywords/keyword_data",
      locals: {
        keyword_target: target,
        keyword: keyword,
        site: target.site,
        checks_by_location: checks_by_location,
        location_stats: location_stats,
        has_checks: true
      }
    )
  end
end
