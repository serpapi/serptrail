class MissingChecksBackfillJob < ApplicationJob
  queue_as :default

  def perform(keyword: nil, keyword_target: nil)
    search_runs_scope(keyword: keyword, keyword_target: keyword_target).find_each do |search_run|
      backfill_search_run(search_run, keyword_target: keyword_target)
    end
  end

  private

  def search_runs_scope(keyword:, keyword_target:)
    scope = SearchRun.includes(keyword: { keyword_targets: :site })
    scope = scope.where(keyword: keyword) if keyword
    scope = scope.where(keyword: keyword_target.keyword) if keyword_target
    scope.where(status: [ :success, :failed ])
  end

  def backfill_search_run(search_run, keyword_target:)
    targets = if keyword_target
      [ keyword_target ]
    else
      search_run.keyword.keyword_targets.includes(:site)
    end

    results = parsed_results(search_run) if search_run.success?

    targets.each do |target|
      next if target.keyword_id != search_run.keyword_id
      next if target.checks.exists?(search_run: search_run)

      if search_run.success?
        next unless results

        create_success_check(target, search_run, results)
      elsif search_run.failed?
        create_failed_check(target, search_run)
      end
    end
  end

  def parsed_results(search_run)
    search_run.combined_results.presence
  end

  def create_success_check(target, search_run, results)
    result = SerpApiClient.new.extract_position(results, target.site.domain, match_subdomains: target.site.match_subdomains)

    target.checks.create!(
      keyword: target.keyword,
      search_run: search_run,
      query: search_run.query,
      location: search_run.location,
      checked_at: search_run.checked_at,
      position: result[:position],
      url: result[:url],
      ai_overview_present: result[:ai_overview_present],
      ai_overview_cited: result[:ai_overview_cited],
      ai_overview_citation_position: result[:ai_overview_citation_position],
      status: :success
    )
  end

  def create_failed_check(target, search_run)
    target.checks.create!(
      keyword: target.keyword,
      search_run: search_run,
      query: search_run.query,
      location: search_run.location,
      checked_at: search_run.checked_at,
      status: :failed,
      error_message: search_run.error_message
    )
  end
end
