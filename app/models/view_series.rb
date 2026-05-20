class ViewSeries < ApplicationRecord
  belongs_to :view
  belongs_to :keyword, optional: true
  belongs_to :keyword_target, optional: true

  validates :location, :position, presence: true
  validate :keyword_or_target_present

  def tracked_keyword
    keyword_target&.keyword || keyword
  end

  def tracked_site
    keyword_target&.site || keyword&.site
  end

  def tracked_checks
    if keyword_target
      keyword_target.checks
    else
      keyword.checks
    end
  end

  private

  def keyword_or_target_present
    errors.add(:base, "keyword target is required") if keyword_target.blank? && keyword.blank?
  end
end
