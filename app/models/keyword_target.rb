class KeywordTarget < ApplicationRecord
  belongs_to :keyword
  belongs_to :site
  has_many :checks, dependent: :destroy

  validates :keyword_id, uniqueness: { scope: :site_id }

  after_create :backfill_checks_from_search_runs!

  scope :tracked, -> { where(tracking_enabled: true).joins(:site).where(sites: { tracking_enabled: true }) }

  delegate :query, :locations, :check_frequency, :last_checked_at, :next_check_at, to: :keyword

  def latest_check(location: nil)
    scoped_checks(location).success.order(checked_at: :desc).first
  end

  def previous_check(location: nil)
    scoped_checks(location).success.order(checked_at: :desc).second
  end

  def position_change(location: nil)
    latest = latest_check(location: location)
    previous = previous_check(location: location)
    return nil unless latest&.position && previous&.position

    previous.position - latest.position
  end

  def backfill_checks_from_search_runs!
    client = SerpApiClient.new

    keyword.search_runs.success.where.not(raw_response: [ nil, "" ]).find_each do |search_run|
      next if checks.exists?(search_run: search_run)

      results = JSON.parse(search_run.raw_response, symbolize_names: true)
      result = client.extract_position(results, site.domain)

      checks.create!(
        keyword: keyword,
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
    rescue JSON::ParserError
      next
    end
  end

  private

  def scoped_checks(location)
    scope = checks
    location.present? ? scope.where(location: location) : scope
  end
end
