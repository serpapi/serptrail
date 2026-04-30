class KeywordsController < ApplicationController
  before_action :set_site
  before_action :set_keyword, only: %i[edit update destroy check]

  def new
    @keyword = @site.keywords.new
  end

  def create
    @keyword = @site.keywords.new(keyword_params)

    if @keyword.save
      redirect_to @site, notice: "Keyword was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @keyword.update(keyword_update_params)
      redirect_to @site, notice: "Keyword was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def check
    @keyword.locations.each { |location| KeywordCheckJob.perform_later(@keyword, location) }
    redirect_to @site, notice: "Ranking check queued for \"#{@keyword.query}\"."
  end

  def destroy
    @keyword.destroy!
    redirect_to @site, notice: "Keyword was successfully deleted."
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end

  def set_keyword
    @keyword = @site.keywords.find(params[:id])
  end

  def keyword_params
    params.expect(keyword: [ :query, :check_frequency, locations: [] ])
  end

  def keyword_update_params
    params.expect(keyword: [ :check_frequency ])
  end
end
