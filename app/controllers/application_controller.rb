class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rate_limit to: 30, within: 1.minute

  http_basic_authenticate_with name: ENV.fetch("HTTP_AUTH_USERNAME"), password: ENV.fetch("HTTP_AUTH_PASSWORD")

  protected

  def slot_duration_for(keyword)
    case keyword.check_frequency.to_s
    when "daily"    then 1.day
    when "weekly"   then 7.days
    when "biweekly" then 14.days
    when "monthly"  then 30.days
    else 7.days
    end
  end

  def parse_search_run(run)
    return [ [], nil ] if run.nil? || run.raw_response.blank?
    data = JSON.parse(run.raw_response, symbolize_names: true)
    [ data[:organic_results] || [], data[:ai_overview].presence ]
  rescue JSON::ParserError
    [ [], nil ]
  end
end
