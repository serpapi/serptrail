require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = auth_headers
    @tenant = tenants(:default)
  end

  test "show renders floating chat widget" do
    get chat_url, headers: @headers

    assert_response :success
    assert_select "turbo-frame#chat_widget"
    assert_select ".chat-widget-toggle"
    assert_select ".chat-widget-panel"
    assert_select "textarea[name='chat[message]']"
  end

  test "layout includes eagerly loaded chat widget frame" do
    get sites_url, headers: @headers

    assert_response :success
    assert_select "turbo-frame#chat_widget[src='#{chat_path}']"
    assert_select "turbo-frame#chat_widget[loading='lazy']", count: 0
  end

  test "show navigates to settings when OpenAI key is missing" do
    original_openai_key = ENV.delete("OPENAI_API_KEY")
    @tenant.update!(openai_api_key: "")

    get chat_url, headers: @headers

    assert_response :success
    assert_select ".chat-widget-setup", text: /Add your OpenAI key/
    assert_select "a[href='#{settings_path}']", text: "Set up API keys"
    assert_select "textarea[name='chat[message]']", count: 0
  ensure
    ENV["OPENAI_API_KEY"] = original_openai_key if original_openai_key
  end

  test "create asks persisted RubyLLM chat and renders answer" do
    with_stubbed_chat_answers("Apple ranks #1 for iphone 18 in the US.") do
      assert_difference("Chat.count", 1) do
        assert_difference("Message.count", 3) do
          post chat_url,
            params: { chat: { message: "How does apple.com rank for iphone 18?" } },
            headers: @headers
        end
      end
    end

    assert_response :success
    assert_select ".chat-widget.is-open"
    assert_select ".chat-message-user", text: /How does apple.com rank/
    assert_select ".chat-message-assistant", text: /Apple ranks #1/
    assert_equal [ "system", "user", "assistant" ], Chat.last.messages.order(:created_at).pluck(:role)
  end

  test "create reuses persisted chat record for follow up context" do
    with_stubbed_chat_answers("First answer", "Follow-up answer") do
      post chat_url, params: { chat: { message: "First question" } }, headers: @headers
      post chat_url, params: { chat: { message: "Follow up" } }, headers: @headers
    end

    assert_response :success
    assert_equal 1, Chat.count
    assert_equal [ "system", "user", "assistant", "user", "assistant" ], Chat.last.messages.order(:created_at).pluck(:role)
    assert_select ".chat-message", count: 4
    assert_select ".chat-message-assistant", text: /Follow-up answer/
  end

  test "renders token and cost usage from persisted messages" do
    with_stubbed_chat_answers("Token-tracked answer", input_tokens: 1200, output_tokens: 80) do
      post chat_url, params: { chat: { message: "Question" } }, headers: @headers
    end

    assert_response :success
    assert_select ".chat-widget-usage", text: /Tokens: 1,200 in \/ 80 out/
  end

  test "renders chat messages as sanitized markdown" do
    with_stubbed_chat_answers("**Summary**\n\n- Apple is #1\n- Best Buy is #5\n\n<script>alert('xss')</script>") do
      post chat_url, params: { chat: { message: "Format this" } }, headers: @headers
    end

    assert_response :success
    assert_select ".chat-message-assistant strong", text: "Summary"
    assert_select ".chat-message-assistant li", text: "Apple is #1"
    assert_select ".chat-message-assistant script", count: 0
  end

  test "destroy clears current persisted chat" do
    with_stubbed_chat_answers("Answer") do
      post chat_url, params: { chat: { message: "Question" } }, headers: @headers
    end

    assert_difference("Chat.count", -1) do
      delete chat_url, headers: @headers
    end

    assert_response :success
    assert_select ".chat-widget-empty"
    assert_select ".chat-message", count: 0
  end

  test "create shows friendly SerpApi invalid key errors" do
    original_ask = Chat.instance_method(:ask)
    Chat.define_method(:ask) do |_prompt|
      raise StandardError, "HTTP request failed with status: 401 Unauthorized error: Invalid API key. Your API key should be here: https://serpapi.com/manage-api-key from url: https://serpapi.com/search"
    end

    post chat_url, params: { chat: { message: "Search Google" } }, headers: @headers

    assert_response :unprocessable_entity
    assert_select ".chat-message-assistant", text: /SerpApi rejected the request because the API key is invalid/
    assert_select ".chat-message-assistant a[href='#{settings_path}']", text: "Open Settings"
    assert_select ".chat-message-assistant", text: { regexp: /from url:/ }, count: 0
  ensure
    Chat.define_method(:ask, original_ask)
  end

  test "create shows friendly OpenAI invalid key errors" do
    original_ask = Chat.instance_method(:ask)
    Chat.define_method(:ask) do |_prompt|
      raise StandardError, "OpenAI API error: 401 Unauthorized - Incorrect API key provided"
    end

    post chat_url, params: { chat: { message: "Summarize rankings" } }, headers: @headers

    assert_response :unprocessable_entity
    assert_select ".chat-message-assistant", text: /OpenAI rejected the request because the API key is invalid/
    assert_select ".chat-message-assistant a[href='#{settings_path}']", text: "Open Settings"
  ensure
    Chat.define_method(:ask, original_ask)
  end

  test "show hides blank persisted assistant messages" do
    with_stubbed_chat_answers("Visible answer") do
      post chat_url, params: { chat: { message: "Question" } }, headers: @headers
    end
    Chat.last.add_message(role: :assistant, content: "")

    get chat_url, headers: @headers

    assert_response :success
    assert_select ".chat-message", count: 2
    assert_select ".chat-message-assistant", text: /Visible answer/
  end

  test "create removes incomplete persisted tool calls before continuing chat" do
    with_stubbed_chat_answers("First answer") do
      post chat_url, params: { chat: { message: "First question" } }, headers: @headers
    end
    chat = Chat.last
    tool_message = chat.messages.create!(role: :assistant, content: "")
    tool_message.tool_calls.create!(tool_call_id: "call_missing", name: "search_google", arguments: { query: "iphone" })

    with_stubbed_chat_answers("Follow-up answer") do
      post chat_url, params: { chat: { message: "Follow up" } }, headers: @headers
    end

    assert_response :success
    assert_empty chat.reload.messages.joins(:tool_calls)
    assert_select ".chat-message-assistant", text: /Follow-up answer/
  end

  private

  def with_stubbed_chat_answers(*answers, input_tokens: nil, output_tokens: nil)
    original_ask = Chat.instance_method(:ask)
    responses = answers.dup

    Chat.define_method(:ask) do |prompt|
      answer = responses.shift || answers.last
      add_message(role: :user, content: prompt)
      assistant_message = add_message(role: :assistant, content: answer)
      assistant_message.update!(llm_model: llm_model, input_tokens: input_tokens, output_tokens: output_tokens)
      Struct.new(:content).new(answer)
    end

    yield
  ensure
    Chat.define_method(:ask, original_ask)
  end
end
