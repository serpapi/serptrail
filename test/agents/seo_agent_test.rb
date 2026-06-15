require "test_helper"

class SeoAgentTest < ActiveSupport::TestCase
  test "registers SEO tools with RubyLLM" do
    agent = SeoAgent.new

    assert_equal [ :check_keyword_position, :search_google, :keyword_history, :find_competitors ], agent.chat.tools.keys
  end

  test "configures RubyLLM with tenant OpenAI key" do
    original_api_key = RubyLLM.config.openai_api_key
    tenants(:default).update!(openai_api_key: "tenant_openai_key")
    RubyLLM.config.openai_api_key = nil

    SeoAgent.new

    assert_equal "tenant_openai_key", RubyLLM.config.openai_api_key
  ensure
    RubyLLM.config.openai_api_key = original_api_key
  end
end
