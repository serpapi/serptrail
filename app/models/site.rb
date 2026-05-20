class Site < ApplicationRecord
  has_many :keywords, dependent: :destroy
  has_many :keyword_targets, dependent: :destroy
  has_many :tracked_keywords, through: :keyword_targets, source: :keyword
  has_many :checks, through: :keyword_targets

  validates :name, presence: true, length: { maximum: 255 }
  validates :domain, presence: true, uniqueness: true, length: { maximum: 253 },
    format: {
      with: /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/,
      message: "must be a valid domain"
    }

  normalizes :domain, with: ->(domain) {
    domain.strip.downcase.sub(%r{\Ahttps?://}, "").chomp("/")
  }
end
