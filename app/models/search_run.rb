class SearchRun < ApplicationRecord
  belongs_to :keyword
  has_many :checks, dependent: :destroy

  validates :query, presence: true
  validates :location, presence: true
  validates :status, presence: true
  validates :engine, presence: true
  validates :checked_at, presence: true

  enum :status, { pending: "pending", success: "success", failed: "failed" }
  enum :engine, { google: "google" }
end
