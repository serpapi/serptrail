class Tenant < ApplicationRecord
  encrypts :serpapi_key
  encrypts :openai_api_key

  def self.instance
    first!
  end
end
