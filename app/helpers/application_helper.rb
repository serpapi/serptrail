module ApplicationHelper
  LOCATION_COLORS = %w[#2563eb #16a34a #dc2626 #9333ea #ea580c #0891b2 #d97706].freeze

  COUNTRY_NAMES = {
    "us" => "United States",   "gb" => "United Kingdom",  "ca" => "Canada",
    "au" => "Australia",       "de" => "Germany",          "fr" => "France",
    "es" => "Spain",           "it" => "Italy",            "nl" => "Netherlands",
    "be" => "Belgium",         "ch" => "Switzerland",      "at" => "Austria",
    "se" => "Sweden",          "no" => "Norway",           "dk" => "Denmark",
    "fi" => "Finland",         "pl" => "Poland",           "pt" => "Portugal",
    "ie" => "Ireland",         "cz" => "Czech Republic",   "hu" => "Hungary",
    "ro" => "Romania",         "ua" => "Ukraine",          "ru" => "Russia",
    "tr" => "Turkey",          "il" => "Israel",           "sa" => "Saudi Arabia",
    "ae" => "United Arab Emirates", "eg" => "Egypt",       "za" => "South Africa",
    "ng" => "Nigeria",         "in" => "India",            "pk" => "Pakistan",
    "bd" => "Bangladesh",      "jp" => "Japan",            "kr" => "South Korea",
    "cn" => "China",           "tw" => "Taiwan",           "hk" => "Hong Kong",
    "sg" => "Singapore",       "my" => "Malaysia",         "id" => "Indonesia",
    "ph" => "Philippines",     "th" => "Thailand",         "vn" => "Vietnam",
    "nz" => "New Zealand",     "br" => "Brazil",           "mx" => "Mexico",
    "ar" => "Argentina",       "cl" => "Chile",            "co" => "Colombia"
  }.freeze

  def next_check_label(keyword)
    next_check = keyword.next_check_at
    if next_check.nil?
      "Checking soon"
    elsif next_check.future?
      "Next check in #{distance_of_time_in_words_to_now(next_check)}"
    else
      "Check due"
    end
  end

  def country_flag(code)
    code.to_s.upcase.chars.map { |c| (0x1F1E6 + (c.ord - "A".ord)).chr(Encoding::UTF_8) }.join
  end

  def country_name(code)
    COUNTRY_NAMES[code.to_s] || code.to_s.upcase
  end

  def location_color(index)
    LOCATION_COLORS[index % LOCATION_COLORS.size]
  end

  def multi_location_sparkline(checks_by_location, locations, width: 960, height: 200)
    all_checks = checks_by_location.values.flatten.sort_by(&:checked_at)
    return nil if all_checks.size < 2

    all_positions = all_checks.filter_map(&:position)
    return nil if all_positions.empty?

    min_pos    = all_positions.min
    max_pos    = all_positions.max
    pos_range  = [max_pos - min_pos, 1].max
    min_time   = all_checks.first.checked_at
    max_time   = all_checks.last.checked_at
    time_span  = [(max_time - min_time).to_f, 1.0].max

    padding_x      = 8
    padding_top    = 8
    padding_bottom = 24
    plot_w = width  - (padding_x * 2)
    plot_h = height - padding_top - padding_bottom
    unranked_y = (padding_top + plot_h).round(1)

    x_for = ->(t) { (padding_x + (t - min_time).to_f / time_span * plot_w).round(1) }
    y_for = ->(p) { (padding_top + (p - min_pos).to_f / pos_range * plot_h).round(1) }

    tag.svg(width: width, height: height, class: "sparkline", viewBox: "0 0 #{width} #{height}") do
      series = safe_join(locations.each_with_index.filter_map do |location, idx|
        loc_checks = (checks_by_location[location] || []).sort_by(&:checked_at)
        next nil if loc_checks.empty?

        color  = location_color(idx)
        points = loc_checks.map do |check|
          { x: x_for.call(check.checked_at),
            y: check.position ? y_for.call(check.position) : unranked_y,
            check: check, ranked: !check.position.nil? }
        end

        lines = safe_join(points.each_cons(2).map { |a, b|
          dashed = !(a[:ranked] && b[:ranked])
          attrs  = { x1: a[:x], y1: a[:y], x2: b[:x], y2: b[:y],
                     stroke: color, stroke_width: 2, stroke_linecap: "round" }
          attrs[:stroke_dasharray] = "4 3" if dashed
          tag.line(**attrs)
        })

        dots = safe_join(points.map { |p|
          label_y     = p[:y] > 20 ? p[:y] - 10 : p[:y] + 18
          label_text  = p[:ranked] ? p[:check].position.to_s : "N/R"
          dot_class   = p[:ranked] ? "sparkline-dot" : "sparkline-dot sparkline-dot-unranked"
          label_class = p[:ranked] ? "sparkline-label" : "sparkline-label sparkline-label-unranked"

          tag.g(class: "sparkline-point") do
            tag.circle(cx: p[:x], cy: p[:y], r: 16, class: "sparkline-hitarea") +
            tag.circle(cx: p[:x], cy: p[:y], r: 4, class: dot_class,
                       style: p[:ranked] ? "fill: #{color}" : nil) +
            tag.text(label_text, x: p[:x], y: label_y, class: label_class)
          end
        })

        lines + dots
      end)

      all_times = all_checks.map(&:checked_at).uniq.sort
      labels = safe_join(all_times.each_with_index.select { |_, i|
        all_times.size <= 6 || i == 0 || i == all_times.size - 1 ||
          (i % (all_times.size / 4.0).ceil == 0)
      }.map { |time, _|
        tag.text(time.strftime("%b %-d"), x: x_for.call(time), y: height - 4,
                 "text-anchor": "middle", class: "sparkline-axis-label")
      })

      series + labels
    end
  end

  def position_sparkline(checks, width: 280, height: 80)
    points = checks.sort_by(&:checked_at)
    ranked = points.select(&:position)
    return nil if points.size < 2 || ranked.empty?

    positions = ranked.map(&:position)
    min_pos = positions.min
    max_pos = positions.max
    range = max_pos - min_pos
    range = 1 if range == 0

    padding_x = 8
    padding_top = 8
    padding_bottom = 24
    plot_w = width - (padding_x * 2)
    plot_h = height - padding_top - padding_bottom
    unranked_y = (padding_top + plot_h).round(1)

    plot_points = points.each_with_index.map do |check, i|
      x = padding_x + (i.to_f / (points.size - 1) * plot_w)
      y = if check.position
        padding_top + ((check.position - min_pos).to_f / range * plot_h)
      else
        unranked_y
      end
      { x: x.round(1), y: y.round(1), check: check, ranked: !check.position.nil? }
    end

    tag.svg(width: width, height: height, class: "sparkline", viewBox: "0 0 #{width} #{height}") do
      # Draw per-pair segments: solid between ranked points, dashed when either end is unranked
      lines = safe_join(plot_points.each_cons(2).map { |a, b|
        dashed = !(a[:ranked] && b[:ranked])
        attrs = {
          x1: a[:x], y1: a[:y], x2: b[:x], y2: b[:y],
          stroke: "#2563eb",
          stroke_width: 2,
          stroke_linecap: "round"
        }
        attrs[:stroke_dasharray] = "4 3" if dashed
        tag.line(**attrs)
      })

      dots = safe_join(plot_points.map { |p|
        # Show label below the dot if too close to the top
        label_y = p[:y] > 20 ? p[:y] - 10 : p[:y] + 18
        label_text = p[:ranked] ? p[:check].position.to_s : "N/R"
        dot_class = p[:ranked] ? "sparkline-dot" : "sparkline-dot sparkline-dot-unranked"
        label_class = p[:ranked] ? "sparkline-label" : "sparkline-label sparkline-label-unranked"

        tag.g(class: "sparkline-point") do
          tag.circle(cx: p[:x], cy: p[:y], r: 16, class: "sparkline-hitarea") +
          tag.circle(cx: p[:x], cy: p[:y], r: 4, class: dot_class) +
          tag.text(label_text, x: p[:x], y: label_y, class: label_class)
        end
      })

      # X-axis date labels
      labels = safe_join(plot_points.select.with_index { |_, i|
        # Show first, last, and evenly spaced labels
        plot_points.size <= 6 || i == 0 || i == plot_points.size - 1 || (i % (plot_points.size / 4.0).ceil == 0)
      }.map { |p|
        tag.text(
          p[:check].checked_at.strftime("%b %-d"),
          x: p[:x], y: height - 4,
          text_anchor: "middle",
          class: "sparkline-axis-label"
        )
      })

      lines + dots + labels
    end
  end
end
