class ChatsController < ApplicationController
  layout false

  helper_method :api_key_error_message?

  MAX_MESSAGES = 20

  before_action :set_tenant

  def show
    @chat = load_chat
    prepare_chat(open: false)
  end

  def create
    prompt = params.dig(:chat, :message).to_s.strip

    if openai_api_key_missing?
      prepare_chat(open: true)
      render :show, status: :unprocessable_entity
      return
    end

    if prompt.blank?
      @chat = load_chat
      prepare_chat(open: true)
      render :show, status: :unprocessable_entity
      return
    end

    @chat = current_chat
    @chat.ask(prompt)

    prepare_chat(open: true)
    render :show
  rescue StandardError => e
    persist_error_message(e)
    prepare_chat(open: true)
    render :show, status: :unprocessable_entity
  end

  def destroy
    load_chat&.destroy
    session.delete(:chat_id)
    @chat = nil
    prepare_chat(open: true)
    render :show
  end

  private

  def set_tenant
    @tenant = Tenant.first
  end

  def prepare_chat(open:)
    @open = open
    @messages = display_messages
    @missing_api_keys = missing_api_keys
    @serpapi_key_missing = serpapi_key_missing?
    @input_tokens = message_scope.sum(:input_tokens)
    @output_tokens = message_scope.sum(:output_tokens)
    @cache_read_tokens = message_scope.sum(:cached_tokens)
    @cache_write_tokens = message_scope.sum(:cache_creation_tokens)
    @cost = @chat&.cost&.total
  end

  def current_chat
    @chat ||= if session[:chat_id] && (chat = Chat.find_by(id: session[:chat_id]))
      cleanup_incomplete_tool_messages(chat)
      SeoAgent.find(chat.id)
    else
      SeoAgent.create!.tap { |new_chat| session[:chat_id] = new_chat.id }
    end
  end

  def load_chat
    return if session[:chat_id].blank?

    Chat.find_by(id: session[:chat_id]).tap do |chat|
      cleanup_incomplete_tool_messages(chat) if chat
    end
  end

  def display_messages
    return [] unless @chat

    @chat.messages
      .where(role: [ "user", "assistant" ])
      .order(:created_at)
      .select { |message| message.content.present? }
      .last(MAX_MESSAGES)
  end

  def message_scope
    @chat&.messages || Message.none
  end

  def persist_error_message(error)
    @chat ||= load_chat
    cleanup_incomplete_tool_messages(@chat) if @chat
    @chat&.add_message(role: :assistant, content: "I couldn't complete that request: #{chat_error_message(error)}")
  end

  def cleanup_incomplete_tool_messages(chat)
    chat.messages.includes(:tool_calls).find_each do |message|
      if message.tool_calls.any? && message.tool_calls.any? { |tool_call| tool_call.result.nil? }
        message.tool_results.destroy_all
        message.destroy
      elsif message.role == "assistant" && message.content.blank? && message.tool_calls.empty?
        message.destroy
      end
    end
  end

  def chat_error_message(error)
    message = error.message.to_s.sub(/\s+from url:\s+\S+\z/i, "")

    return "SerpApi rejected the request because the API key is invalid. Update your SerpApi key in Settings." if serpapi_key_error?(message)
    return "OpenAI rejected the request because the API key is invalid. Update your OpenAI key in Settings." if openai_key_error?(message)

    message
  end

  def api_key_error_message?(content)
    content.to_s.match?(/Update your (OpenAI|SerpApi) key in Settings\./)
  end

  def serpapi_key_error?(message)
    message.match?(/invalid api key|unauthorized|401/i) && message.match?(/serpapi|manage-api-key|serpapi\.com/i)
  end

  def openai_key_error?(message)
    message.match?(/invalid api key|incorrect api key|invalid_api_key|unauthorized|401/i) &&
      message.match?(/openai|api key/i)
  end

  def missing_api_keys
    keys = []
    keys << "OpenAI" if openai_api_key_missing?
    keys << "SerpApi" if serpapi_key_missing?
    keys
  end

  def openai_api_key_missing?
    @tenant&.openai_api_key.blank?
  end

  def serpapi_key_missing?
    @tenant&.serpapi_key.blank?
  end
end
