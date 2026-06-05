class Keyword < ApplicationRecord
  belongs_to :site, optional: true
  has_many :keyword_targets, dependent: :destroy
  has_many :target_sites, through: :keyword_targets, source: :site
  has_many :checks, dependent: :destroy
  has_many :search_runs, dependent: :destroy
  has_many :view_series, dependent: :destroy

  validates :query, presence: true, uniqueness: { scope: :site_id }, length: { maximum: 255 }
  validates :check_frequency, presence: true
  validates :locations, presence: true

  before_validation :set_default_locations
  after_create :ensure_primary_keyword_target

  enum :check_frequency, { daily: "daily", weekly: "weekly", biweekly: "biweekly", monthly: "monthly" }

  scope :due_for_check, -> {
    left_joins(:keyword_targets)
      .where(
        "keyword_targets.id IS NULL OR keyword_targets.tracking_enabled = :target_tracking_enabled",
        target_tracking_enabled: true
      )
      .distinct
      .where(
      "keywords.last_checked_at IS NULL OR " \
      "(keywords.check_frequency = 'daily' AND keywords.last_checked_at <= :daily) OR " \
      "(keywords.check_frequency = 'weekly' AND keywords.last_checked_at <= :weekly) OR " \
      "(keywords.check_frequency = 'biweekly' AND keywords.last_checked_at <= :biweekly) OR " \
      "(keywords.check_frequency = 'monthly' AND keywords.last_checked_at <= :monthly)",
      daily: 1.day.ago,
      weekly: 1.week.ago,
      biweekly: 2.weeks.ago,
      monthly: 1.month.ago
    )
  }

  FREQUENCY_DURATION = {
    "daily"    => 1.day,
    "weekly"   => 1.week,
    "biweekly" => 2.weeks,
    "monthly"  => 1.month
  }.freeze

  def next_check_at
    return nil unless last_checked_at
    last_checked_at + FREQUENCY_DURATION[check_frequency]
  end

  def target_for(site)
    keyword_targets.detect { |target| target.site_id == site.id } || keyword_targets.find_by(site: site)
  end

  def latest_check(site: nil, location: nil)
    scoped_checks(site, location).where(status: "success").order(checked_at: :desc).first
  end

  def previous_check(site: nil, location: nil)
    scoped_checks(site, location).where(status: "success").order(checked_at: :desc).second
  end

  def position_change(site: nil, location: nil)
    latest = latest_check(site: site, location: location)
    previous = previous_check(site: site, location: location)
    return nil unless latest&.position && previous&.position

    previous.position - latest.position
  end

  private

  def set_default_locations
    self.locations = [ "us" ] if locations.blank?
  end

  def ensure_primary_keyword_target
    keyword_targets.find_or_create_by!(site: site) if site
  end

  def scoped_checks(site, location)
    scope = if site
      target = target_for(site)
      target ? target.checks : checks.none
    else
      checks
    end

    location.present? ? scope.where(location: location) : scope
  end
end
