class KeywordTarget < ApplicationRecord
  belongs_to :keyword
  belongs_to :site
  has_many :checks, dependent: :destroy
  has_many :view_series, dependent: :destroy

  validates :keyword_id, uniqueness: { scope: :site_id }

  after_create_commit :backfill_checks_from_search_runs_later

  scope :tracked, -> { where(tracking_enabled: true) }

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

  private

  def backfill_checks_from_search_runs_later
    MissingChecksBackfillJob.perform_later(keyword_target: self)
  end


  def scoped_checks(location)
    scope = checks
    location.present? ? scope.where(location: location) : scope
  end
end
