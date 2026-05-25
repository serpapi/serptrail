class KeywordsController < ApplicationController
  before_action :set_keyword, only: %i[show edit update destroy check]
  before_action :load_sites, only: %i[new edit create update]

  def index
    @keywords = Keyword.includes(keyword_targets: :site).order(:query)
  end

  def show
    @keyword_targets = @keyword.keyword_targets.includes(:site).joins(:site).order("sites.name")
    @search_runs = @keyword.search_runs.order(checked_at: :asc)
    @latest_search_run = @search_runs.where(status: :success).last
  end

  def new
    @keyword = Keyword.new
  end

  def create
    @keyword = Keyword.find_by(query: keyword_params[:query]) || Keyword.new
    @keyword.assign_attributes(keyword_attributes)

    if @keyword.save
      sync_keyword_targets(@keyword, selected_site_ids)
      queue_keyword_checks(@keyword)
      redirect_to keyword_path(@keyword), notice: "Keyword was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @keyword.assign_attributes(keyword_attributes)

    if @keyword.save
      sync_keyword_targets(@keyword, selected_site_ids)
      redirect_to keyword_path(@keyword), notice: "Keyword was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def check
    queue_keyword_checks(@keyword)
    redirect_to keyword_path(@keyword), notice: "Ranking check queued for \"#{@keyword.query}\"."
  end

  def destroy
    @keyword.destroy!
    redirect_to keywords_path, notice: "Keyword was successfully deleted."
  end

  private

  def set_keyword
    @keyword = Keyword.find(params[:id])
  end

  def load_sites
    @sites = Site.order(:name)
  end

  def keyword_params
    params.expect(keyword: [ :query, :check_frequency, site_ids: [], locations: [] ])
  end

  def keyword_attributes
    keyword_params.except(:site_ids)
  end

  def selected_site_ids
    keyword_params[:site_ids].to_a.reject(&:blank?).map(&:to_i)
  end

  def sync_keyword_targets(keyword, site_ids)
    current_site_ids = keyword.keyword_targets.pluck(:site_id)

    (current_site_ids - site_ids).each do |site_id|
      keyword.keyword_targets.find_by(site_id: site_id)&.destroy!
    end

    (site_ids - current_site_ids).each do |site_id|
      keyword.keyword_targets.find_or_create_by!(site_id: site_id)
    end
  end

  def queue_keyword_checks(keyword)
    keyword.locations.each do |location|
      KeywordCheckJob.perform_later(keyword, location)
    end
    keyword.update_column(:last_checked_at, Time.current)
  end
end
