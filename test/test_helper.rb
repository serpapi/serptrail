ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def auth_headers
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV.fetch("HTTP_AUTH_USERNAME"), ENV.fetch("HTTP_AUTH_PASSWORD")
      )
      { "Authorization" => credentials }
    end
  end
end
