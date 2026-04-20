class ChecksController < ApplicationController
  before_action :set_site
  before_action :set_keyword

  def index
    @checks = @keyword.checks.order(checked_at: :desc)
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end

  def set_keyword
    @keyword = @site.keywords.find(params[:keyword_id])
  end
end
