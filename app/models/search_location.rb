class SearchLocation
  CITY_PREFIX = "city"

  attr_reader :value

  def self.city_value(canonical_name:, country_code:)
    [ CITY_PREFIX, country_code.to_s.downcase, canonical_name ].join(":")
  end

  def initialize(value)
    @value = value.to_s
  end

  def city?
    value.start_with?("#{CITY_PREFIX}:")
  end

  def country_code
    city? ? city_parts.fetch(1) : value
  end

  def canonical_name
    city? ? city_parts.fetch(2) : nil
  end

  def display_name
    canonical_name&.gsub(",", ", ")
  end

  def search_params
    return { gl: value } unless city?

    { location: canonical_name, gl: country_code }
  end

  private

  def city_parts
    @city_parts ||= value.split(":", 3)
  end
end
