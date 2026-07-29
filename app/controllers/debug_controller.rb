class DebugController < ApplicationController
  def index
    @serpapi_key_present = Tenant.instance.serpapi_key.present?
    @openai_key_present = Tenant.instance.openai_api_key.present?

    @search_runs = SearchRun.includes(:keyword, :search_run_pages, checks: { keyword_target: :site })
      .order(checked_at: :desc)
      .limit(1000)
  end
end
