class View < ApplicationRecord
  has_many :series, -> { order(:position) }, class_name: "ViewSeries", dependent: :destroy

  validates :name, presence: true
end
