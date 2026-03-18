class Check < ApplicationRecord
  belongs_to :keyword

  validates :status, presence: true
  validates :checked_at, presence: true

  enum :status, { pending: "pending", success: "success", failed: "failed" }
end
