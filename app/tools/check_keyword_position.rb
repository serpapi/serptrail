class CheckKeywordPosition < RubyLLM::Tool
  desc "Check where a domain ranks on Google for a given search query"

  params do
    string :query, description: "The search query/keyword to check"
    string :domain, description: "The domain to find in results (e.g., example.com)"
    string :location, description: "Google country code/location to search from (default: us)", required: false
    boolean :match_subdomains, description: "Whether to consider results from subdomains as matching", required: false
  end

  def execute(query:, domain:, location: "us", match_subdomains: false)
    SerpApiClient.new.check_position(query, domain, location: location.presence || "us", match_subdomains: match_subdomains)
  end
end
