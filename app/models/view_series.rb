class ViewSeries < ApplicationRecord
  belongs_to :view
  belongs_to :keyword

  validates :location, :position, presence: true
end
