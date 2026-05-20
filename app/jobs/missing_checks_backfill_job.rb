class MissingChecksBackfillJob < ApplicationJob
  queue_as :default

  def perform(keyword: nil, keyword_target: nil)
    repair_legacy_checks(keyword: keyword, keyword_target: keyword_target)

    search_runs_scope(keyword: keyword, keyword_target: keyword_target).find_each do |search_run|
      backfill_search_run(search_run, keyword_target: keyword_target)
    end
  end

  private

  def repair_legacy_checks(keyword:, keyword_target:)
    scope = Check.includes(:keyword, keyword: :site).where("keyword_target_id IS NULL OR search_run_id IS NULL")
    scope = scope.where(keyword: keyword) if keyword
    scope = scope.where(keyword: keyword_target.keyword) if keyword_target

    scope.find_each do |check|
      target = legacy_target_for(check, keyword_target: keyword_target)
      next unless target

      search_run = check.search_run || search_run_for_legacy_check(check)
      updates = {}
      updates[:keyword_target_id] = target.id if check.keyword_target_id.blank?
      updates[:search_run_id] = search_run.id if check.search_run_id.blank?
      updates[:updated_at] = Time.current if updates.any?
      check.update_columns(updates) if updates.any?
    end
  end

  def legacy_target_for(check, keyword_target:)
    return keyword_target if keyword_target && keyword_target.keyword_id == check.keyword_id

    site = check.keyword.site
    return nil unless site

    KeywordTarget.find_or_create_by!(keyword: check.keyword, site: site)
  end

  def search_run_for_legacy_check(check)
    check.keyword.search_runs.find_or_create_by!(
      query: check[:query],
      location: check[:location],
      checked_at: check[:checked_at]
    ) do |search_run|
      search_run.status = check[:status]
      search_run.error_message = check[:error_message]
    end
  end

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
    return nil if search_run.raw_response.blank?

    JSON.parse(search_run.raw_response, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.warn("Skipping SearchRun #{search_run.id}: raw_response could not be parsed: #{e.message}")
    nil
  end

  def create_success_check(target, search_run, results)
    result = SerpApiClient.new.extract_position(results, target.site.domain)

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
