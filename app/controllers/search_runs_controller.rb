class SearchRunsController < ApplicationController
  before_action :set_keyword

  def index
    @search_runs = @keyword.search_runs.order(checked_at: :asc)
    @chart_end = params[:chart_end].present? ? Time.at(params[:chart_end].to_i).utc : nil
    if params[:slot].present?
      @selected_slot_start = Time.at(params[:slot].to_i).utc
      slot_end = @selected_slot_start + slot_duration_for(@keyword)
      runs = @keyword.search_runs.where(status: :success, checked_at: @selected_slot_start..slot_end).order(:checked_at)
      @runs_by_location = runs.each_with_object({}) { |r, h| h[r.location] = r }
      @selected_location = params[:location] || @runs_by_location.keys.first
      @selected_run = @runs_by_location[@selected_location]
    else
      @runs_by_location = {}
    end
    @organic_results, @ai_overview = parse_search_run(@selected_run)
  end

  def show
    @search_run = @keyword.search_runs.find(params[:id])
    data = @search_run.combined_results
    @organic_results = data[:organic_results] || []
    @ai_overview = data[:ai_overview].presence
  end

  private

  def set_keyword
    @keyword = Keyword.find(params[:keyword_id])
  end
end
