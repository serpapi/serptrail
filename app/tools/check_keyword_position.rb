class CheckKeywordPosition < RubyLLM::Tool
  description "Check where a domain ranks on Google for a given search query"

  params do
    string :query, description: "The search query/keyword to check"
    string :domain, description: "The domain to find in results (e.g., example.com)"
  end

  def execute(query:, domain:)
    SerpApiClient.new.check_position(query, domain)
  end
end
