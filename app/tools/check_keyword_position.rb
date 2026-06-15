class CheckKeywordPosition < RubyLLM::Tool
  desc "Check where a domain ranks on Google for a given search query"

  params do
    string :query, description: "The search query/keyword to check"
    string :domain, description: "The domain to find in results (e.g., example.com)"
    string :location, description: "Google country code/location to search from (default: us)", required: false
  end

  def execute(query:, domain:, location: "us")
    SerpApiClient.new.check_position(query, domain, location: location.presence || "us")
  end
end
