class Tenant < ApplicationRecord
  encrypts :serpapi_key

  validates :serpapi_key, presence: true

  def self.instance
    first!
  end
end
