class SearchRunPage < ApplicationRecord
  belongs_to :search_run

  validates :page_number, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :start, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :page_number, uniqueness: { scope: :search_run_id }

  enum :status, { pending: "pending", success: "success", failed: "failed" }

  def response_data
    return {} if raw_response.blank?

    JSON.parse(raw_response, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

  def organic_results
    Array(response_data[:organic_results]).each_with_index.map do |result, index|
      reported_position = result[:position].to_i
      absolute_position = if reported_position > start
        reported_position
      elsif reported_position.positive?
        start + reported_position
      else
        start + index + 1
      end
      result.merge(position: absolute_position, page: page_number)
    end
  end

  def ai_overview
    response_data[:ai_overview].presence
  end
end
