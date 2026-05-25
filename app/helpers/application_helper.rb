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

  def empty_state(message, link_label = nil, link_url = nil)
    content_tag(:div, class: "empty-state") do
      content_tag(:p, message, class: "empty-state-title") +
        (link_label ? link_to(link_label, link_url, class: "btn btn-lg") : "".html_safe)
    end
  end

  # Renders the full chart component: sparkline + legend + empty state.
  def search_runs_timeline(search_runs, link_for: nil, width: 960)
    runs = search_runs.select(&:success?).sort_by(&:checked_at)
    return nil if runs.empty?

    locations = runs.map(&:location).uniq

    padding_left   = 36
    padding_right  = 8
    padding_top    = 8
    padding_bottom = 24
    row_height     = 40
    plot_w = width - padding_left - padding_right
    height = padding_top + locations.size * row_height + padding_bottom

    min_time  = runs.first.checked_at
    max_time  = runs.last.checked_at
    time_span = [(max_time - min_time).to_f, 1.0].max

    x_for = ->(t) { (padding_left + (t - min_time).to_f / time_span * plot_w).round(1) }

    tag.svg(width: width, height: height, class: "sparkline", viewBox: "0 0 #{width} #{height}") do
      rows = safe_join(locations.each_with_index.map { |location, idx|
        y     = padding_top + idx * row_height + row_height / 2
        color = location_color(idx)

        track     = tag.line(x1: padding_left, y1: y, x2: padding_left + plot_w, y2: y,
                             stroke: "#e5e7eb", stroke_width: 1)
        loc_label = tag.text(country_flag(location), x: padding_left - 4, y: y + 4,
                             "text-anchor": "end", class: "sparkline-axis-label")

        dots = safe_join(runs.select { |r| r.location == location }.map { |run|
          x = x_for.call(run.checked_at)

          g_attrs = { class: "sparkline-point" }
          if link_for && (url = link_for.call(run))
            g_attrs[:data] = { "search-run-url": url, action: "click->chart-nav#navigate" }
          end

          tag.g(**g_attrs) do
            tag.circle(cx: x, cy: y, r: 16, class: "sparkline-hitarea") +
            tag.circle(cx: x, cy: y, r: 5, style: "fill: #{color}; opacity: 1") +
            tag.text(run.checked_at.strftime("%b %-d"), x: x, y: y - 12,
                     class: "sparkline-label", "text-anchor": "middle")
          end
        })

        track + loc_label + dots
      })

      all_times = runs.map(&:checked_at).sort
      x_labels  = safe_join(all_times.each_with_index.select { |_, i|
        all_times.size <= 6 || i == 0 || i == all_times.size - 1 ||
          (i % (all_times.size / 4.0).ceil == 0)
      }.map { |time, _|
        tag.text(time.strftime("%b %-d"), x: x_for.call(time), y: height - 4,
                 "text-anchor": "middle", class: "sparkline-axis-label")
      })

      rows + x_labels
    end
  end

  # series: array of { label: String, checks: Array }
  def ranking_chart(series, width: 960, height: 220, empty_message: "Not enough data yet.", link_for: nil, wrapper_data: {})
    render "shared/chart", series: series, width: width, height: height, empty_message: empty_message, link_for: link_for, wrapper_data: wrapper_data
  end

  def multi_location_sparkline(checks_by_location, locations, width: 960, height: 200, link_for: nil)
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

    padding_left   = 36
    padding_right  = 8
    padding_top    = 8
    padding_bottom = 24
    plot_w = width  - padding_left - padding_right
    plot_h = height - padding_top  - padding_bottom
    unranked_y = (padding_top + plot_h).round(1)

    x_for = ->(t) { (padding_left + (t - min_time).to_f / time_span * plot_w).round(1) }
    y_for = ->(p) { (padding_top  + (p - min_pos).to_f  / pos_range  * plot_h).round(1) }

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

          g_attrs = { class: "sparkline-point" }
          if link_for && (url = link_for.call(p[:check]))
            g_attrs[:data] = { "search-run-url": url, action: "click->chart-nav#navigate" }
          end

          tag.g(**g_attrs) do
            tag.circle(cx: p[:x], cy: p[:y], r: 16, class: "sparkline-hitarea") +
            tag.circle(cx: p[:x], cy: p[:y], r: 4, class: dot_class,
                       style: p[:ranked] ? "fill: #{color}" : nil) +
            tag.text(label_text, x: p[:x], y: label_y, class: label_class)
          end
        })

        lines + dots
      end)

      # X-axis date labels
      all_times = all_checks.map(&:checked_at).uniq.sort
      x_labels = safe_join(all_times.each_with_index.select { |_, i|
        all_times.size <= 6 || i == 0 || i == all_times.size - 1 ||
          (i % (all_times.size / 4.0).ceil == 0)
      }.map { |time, _|
        tag.text(time.strftime("%b %-d"), x: x_for.call(time), y: height - 4,
                 "text-anchor": "middle", class: "sparkline-axis-label")
      })

      # Y-axis position labels
      num_y_ticks = [pos_range, 4].min + 1
      y_tick_values = (0...num_y_ticks).map { |i|
        (min_pos + i.to_f * (max_pos - min_pos) / [num_y_ticks - 1, 1].max).round
      }.uniq
      y_labels = safe_join(y_tick_values.map { |pos|
        tag.text(pos.to_s, x: padding_left - 4, y: y_for.call(pos) + 4,
                 "text-anchor": "end", class: "sparkline-axis-label")
      })

      series + x_labels + y_labels
    end
  end

  def position_sparkline(checks, width: 280, height: 80)
    points = checks.sort_by(&:checked_at)
    ranked = points.select(&:position)
    return nil if points.size < 2 || ranked.empty?

    positions = ranked.map(&:position)
    min_pos = positions.min
    max_pos = positions.max
    pos_range  = [max_pos - min_pos, 1].max

    padding_left   = 32
    padding_right  = 8
    padding_top    = 8
    padding_bottom = 24
    plot_w = width  - padding_left - padding_right
    plot_h = height - padding_top  - padding_bottom
    unranked_y = (padding_top + plot_h).round(1)

    y_for = ->(p) { (padding_top + (p - min_pos).to_f / pos_range * plot_h).round(1) }

    plot_points = points.each_with_index.map do |check, i|
      x = padding_left + (i.to_f / (points.size - 1) * plot_w)
      y = check.position ? y_for.call(check.position) : unranked_y
      { x: x.round(1), y: y.round(1), check: check, ranked: !check.position.nil? }
    end

    tag.svg(width: width, height: height, class: "sparkline", viewBox: "0 0 #{width} #{height}") do
      lines = safe_join(plot_points.each_cons(2).map { |a, b|
        dashed = !(a[:ranked] && b[:ranked])
        attrs = {
          x1: a[:x], y1: a[:y], x2: b[:x], y2: b[:y],
          stroke: "#2563eb", stroke_width: 2, stroke_linecap: "round"
        }
        attrs[:stroke_dasharray] = "4 3" if dashed
        tag.line(**attrs)
      })

      dots = safe_join(plot_points.map { |p|
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
      x_labels = safe_join(plot_points.select.with_index { |_, i|
        plot_points.size <= 6 || i == 0 || i == plot_points.size - 1 ||
          (i % (plot_points.size / 4.0).ceil == 0)
      }.map { |p|
        tag.text(p[:check].checked_at.strftime("%b %-d"), x: p[:x], y: height - 4,
                 "text-anchor": "middle", class: "sparkline-axis-label")
      })

      # Y-axis position labels
      num_y_ticks = [pos_range, 3].min + 1
      y_tick_values = (0...num_y_ticks).map { |i|
        (min_pos + i.to_f * (max_pos - min_pos) / [num_y_ticks - 1, 1].max).round
      }.uniq
      y_labels = safe_join(y_tick_values.map { |pos|
        tag.text(pos.to_s, x: padding_left - 4, y: y_for.call(pos) + 4,
                 "text-anchor": "end", class: "sparkline-axis-label")
      })

      lines + dots + x_labels + y_labels
    end
  end
end
