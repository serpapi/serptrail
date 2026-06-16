class SeoAgent < RubyLLM::Agent
  chat_model Chat
  model ENV.fetch("CHAT_MODEL", "gpt-4o-mini")

  instructions <<~PROMPT
    You are an SEO research assistant for SerpTrail, a keyword ranking tracker.

    You help users investigate Google search rankings, analyze competitors, and
    review historical position data for the sites and keywords they track.

    Use the tools available to you whenever a question requires live search data
    or stored ranking history. Prefer the database-backed tools (KeywordHistory)
    for past performance across one or more keyword/site combinations, and the
    SerpApi-backed tools (SearchGoogle, CheckKeywordPosition, FindCompetitors)
    for live lookups.

    When presenting results, be concise and structured: lead with the answer,
    then list supporting positions, URLs, and any notable changes.
  PROMPT

  tools CheckKeywordPosition,
        SearchGoogle,
        KeywordHistory,
        FindCompetitors

  def self.create!(...)
    configure_openai_api_key
    super
  end

  def self.find(...)
    configure_openai_api_key
    super
  end

  def self.configure_openai_api_key
    api_key = Tenant.first&.openai_api_key.presence || ENV["OPENAI_API_KEY"].presence
    RubyLLM.config.openai_api_key = api_key
  end

  def initialize(...)
    self.class.configure_openai_api_key
    super
  end
end
