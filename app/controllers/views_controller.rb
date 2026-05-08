class ViewsController < ApplicationController
  def index
    @sites = Site.order(:name)
    @all_keywords = Keyword.includes(:site).order(:query)

    s1, s2 = params[:s1], params[:s2]
    if s1&.dig(:keyword_id).present? && s1&.dig(:location).present? &&
       s2&.dig(:keyword_id).present? && s2&.dig(:location).present?
      @series1 = fetch_series(s1)
      @series2 = fetch_series(s2)
    end
  end

  private

  def fetch_series(p)
    keyword = Keyword.includes(:site).find(p[:keyword_id])
    checks  = keyword.checks
                     .where(status: "success", location: p[:location])
                     .order(checked_at: :asc)
    { keyword: keyword, site: keyword.site, location: p[:location], checks: checks.to_a }
  end
end
