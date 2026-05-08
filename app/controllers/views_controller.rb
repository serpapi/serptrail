class ViewsController < ApplicationController
  before_action :set_view, only: [ :show, :edit, :update, :destroy ]
  before_action :load_form_data, only: [ :new, :edit ]

  def index
    @views = View.includes(series: { keyword: [ :site, :checks ] }).order(:name)
  end

  def show
  end

  def new
    s1, s2 = params[:s1], params[:s2]
    if s1&.dig(:keyword_id).present? && s1&.dig(:location).present? &&
       s2&.dig(:keyword_id).present? && s2&.dig(:location).present?
      @series1 = fetch_series(s1)
      @series2 = fetch_series(s2)
    end
  end

  def create
    @view = View.new(name: params.dig(:view, :name))
    (params.dig(:view, :series) || {}).each do |idx, sp|
      @view.series.build(keyword_id: sp[:keyword_id], location: sp[:location], position: idx.to_i)
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
      @view.series.build(keyword_id: sp[:keyword_id], location: sp[:location], position: idx.to_i)
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

  def set_view
    @view = View.includes(series: { keyword: [ :site, :checks ] }).find(params[:id])
  end

  def load_form_data
    @sites = Site.order(:name)
    @all_keywords = Keyword.includes(:site).order(:query)
  end

  def fetch_series(p)
    keyword = Keyword.includes(:site).find(p[:keyword_id])
    checks  = keyword.checks
                     .where(status: "success", location: p[:location])
                     .order(checked_at: :asc)
    { keyword: keyword, site: keyword.site, location: p[:location], checks: checks.to_a }
  end
end
