class ChecksController < ApplicationController
  def index
    @keyword = Keyword.find(params[:keyword_id])
    @site = @keyword.site
    @checks = @keyword.checks.order(checked_at: :desc)
  end
end
