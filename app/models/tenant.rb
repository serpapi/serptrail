class Tenant < ApplicationRecord
  encrypts :serpapi_key


  def self.instance
    first!
  end
end
