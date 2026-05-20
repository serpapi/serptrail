class ViewsController < ApplicationController
  before_action :set_view, only: [ :show, :edit, :update, :destroy ]
  before_action :load_form_data, only: [ :new, :edit ]

  def index
    @views = View.includes(series: { keyword_target: [ :site, :keyword, :checks ] }).order(:name)
  end

  def show
  end

  def new
    s1, s2 = params[:s1], params[:s2]
    if series_params_present?(s1) && series_params_present?(s2)
      @series1 = fetch_series(s1)
      @series2 = fetch_series(s2)
    end
  end

  def create
    @view = View.new(name: params.dig(:view, :name))
    (params.dig(:view, :series) || {}).each do |idx, sp|
      build_series(@view, sp, idx)
    end
    if @view.save
      redirect_to views_path, notice: "View saved."
    else
      redirect_to new_view_path, alert: @view.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    @view.assign_attributes(name: params.dig(:view, :name).presence || @view.name)
    @view.series.destroy_all
    (params.dig(:view, :series) || {}).each do |idx, sp|
      build_series(@view, sp, idx)
    end
    if @view.save
      redirect_to view_path(@view), notice: "View updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @view.destroy
    redirect_to views_path, notice: "View deleted."
  end

  private

  def build_series(view, series_params, index)
    target = KeywordTarget.find(series_params[:keyword_target_id] || series_params[:keyword_id])
    view.series.build(
      keyword_target: target,
      keyword: target.keyword,
      location: series_params[:location],
      position: index.to_i
    )
  end

  def set_view
    @view = View.includes(series: { keyword_target: [ :site, :keyword, :checks ] }).find(params[:id])
  end

  def load_form_data
    @sites = Site.order(:name)
    @all_keyword_targets = KeywordTarget.includes(:site, :keyword).joins(:keyword).order("keywords.query")
  end

  def series_params_present?(params_hash)
    (params_hash&.dig(:keyword_target_id).present? || params_hash&.dig(:keyword_id).present?) && params_hash&.dig(:location).present?
  end

  def fetch_series(p)
    target = KeywordTarget.includes(:site, :keyword, checks: :search_run).find(p[:keyword_target_id] || p[:keyword_id])
    checks = target.checks
      .where(status: "success", location: p[:location])
      .order(checked_at: :asc)
    { keyword_target: target, keyword: target.keyword, site: target.site, location: p[:location], checks: checks.to_a }
  end
end
