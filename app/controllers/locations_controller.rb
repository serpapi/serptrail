class LocationsController < ApplicationController
  def index
    query = params[:q].to_s.strip
    return render json: [] if query.length < 2

    locations = Rails.cache.fetch([ "serpapi-locations", query.downcase ], expires_in: 1.day) do
      SerpApiLocationsClient.new.search(query)
    end
    render json: locations
  rescue SerpApiLocationsClient::Error => e
    Rails.logger.warn(e.message)
    render json: { error: "Locations are temporarily unavailable." }, status: :bad_gateway
  end
end
