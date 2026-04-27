class Keyword < ApplicationRecord
  belongs_to :site
  has_many :checks, dependent: :destroy

  validates :query, presence: true, uniqueness: { scope: :site_id }, length: { maximum: 255 }
  validates :check_frequency, presence: true
  validates :location, presence: true

  enum :check_frequency, { daily: "daily", weekly: "weekly", biweekly: "biweekly", monthly: "monthly" }

  scope :due_for_check, -> {
    joins(:site).where(sites: { tracking_enabled: true }).where(
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

  def latest_check
    checks.where(status: "success").order(checked_at: :desc).first
  end

  def previous_check
    checks.where(status: "success").order(checked_at: :desc).second
  end

  def position_change
    latest = latest_check
    previous = previous_check
    return nil unless latest&.position && previous&.position

    previous.position - latest.position
  end
end
