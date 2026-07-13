class SearchRun < ApplicationRecord
  belongs_to :keyword
  has_many :checks, dependent: :destroy
  has_many :search_run_pages, -> { order(:page_number) }, dependent: :destroy

  validates :query, presence: true
  validates :location, presence: true
  validates :status, presence: true
  validates :engine, presence: true
  validates :checked_at, presence: true
  validates :requested_pages, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  enum :status, { pending: "pending", success: "success", failed: "failed" }
  enum :engine, { google: "google" }

  def combined_results
    pages = search_run_pages.success.to_a
    return legacy_results if pages.empty?

    {
      organic_results: pages.flat_map(&:organic_results),
      ai_overview: pages.find { |page| page.page_number == 1 }&.ai_overview
    }.compact
  end

  def serpapi_search_id
    self[:serpapi_search_id].presence || search_run_pages.first&.serpapi_search_id
  end

  private

  def legacy_results
    return {} if raw_response.blank?

    JSON.parse(raw_response, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end
end
