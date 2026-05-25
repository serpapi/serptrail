class SearchRunsController < ApplicationController
  def show
    @keyword = Keyword.find(params[:keyword_id])
    @search_run = @keyword.search_runs.find(params[:id])
    parse_raw_response
  end

  private

  def parse_raw_response
    @organic_results = []
    @ai_overview = nil
    return if @search_run.raw_response.blank?

    data = JSON.parse(@search_run.raw_response, symbolize_names: true)
    @organic_results = data[:organic_results] || []
    @ai_overview = data[:ai_overview].presence
  rescue JSON::ParserError
    nil
  end
end
