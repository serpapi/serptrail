class ViewSeries < ApplicationRecord
  belongs_to :view
  belongs_to :keyword_target
  belongs_to :keyword

  validates :location, :position, presence: true

  def tracked_keyword
    keyword_target.keyword
  end

  def tracked_site
    keyword_target.site
  end

  def tracked_checks
    keyword_target.checks
  end
end
