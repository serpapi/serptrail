class Site < ApplicationRecord
  has_many :keywords, dependent: :destroy

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: true

  normalizes :domain, with: ->(domain) {
    domain.strip.downcase.sub(%r{\Ahttps?://}, "").chomp("/")
  }
end
