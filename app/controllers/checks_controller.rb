class ChecksController < ApplicationController
  before_action :set_site
  before_action :set_keyword_target

  def index
    @keyword = @keyword_target.keyword
    @checks = @keyword_target.checks.includes(:search_run).order(checked_at: :desc)
  end

  private

  def set_site
    @site = Site.find(params[:site_id])
  end

  def set_keyword_target
    @keyword_target = @site.keyword_targets.includes(:keyword).find_by!(keyword_id: params[:keyword_id])
  end
end
