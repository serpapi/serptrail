class SitesController < ApplicationController
  before_action :set_site, only: %i[show table edit update destroy]

  def index
    @sites = Site.all.order(:name)
  end

  def show
    @keyword_targets = @site.keyword_targets.includes(:site, :keyword, checks: :search_run).joins(:keyword).order("keywords.query")
  end

  def table
    @keyword_targets = @site.keyword_targets.includes(:site, :keyword, checks: :search_run).joins(:keyword).order("keywords.query")
  end

  def new
    @site = Site.new
  end

  def create
    @site = Site.new(site_params)

    if @site.save
      redirect_to @site
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: "Site was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy!
    redirect_to sites_path, notice: "Site was successfully deleted."
  end

  private

  def set_site
    @site = Site.find(params[:id])
  end

  def site_params
    params.expect(site: [ :name, :domain ])
  end
end
