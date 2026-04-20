class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rate_limit to: 30, within: 1.minute

  http_basic_authenticate_with name: ENV.fetch("HTTP_AUTH_USERNAME"), password: ENV.fetch("HTTP_AUTH_PASSWORD")
end
