#!/usr/bin/env ruby
# Run with: bin/rails runner chat.rb "your question here"

require_relative "config/environment"

RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
end

agent = SeoAgent.new
agent.on_tool_call { |tc| puts "=> Calling tool: #{tc.name}(#{tc.arguments})" }

question = ARGV[0] || "What are the top 5 Google results for 'ruby on rails hosting'?"

puts "Question: #{question}"
puts
response = agent.ask(question)
puts
puts response.content
