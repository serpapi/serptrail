#!/usr/bin/env ruby
# Run with: bin/rails runner chat.rb "your question here"

require_relative "config/environment"

agent = SeoAgent.new
agent.before_tool_call { |tc| puts "=> Calling tool: #{tc.name}(#{tc.arguments})" }

question = ARGV[0] || "What are the top 5 Google results for 'ruby on rails hosting'?"

puts "Question: #{question}"
puts
response = agent.ask(question)
puts
puts response.content
