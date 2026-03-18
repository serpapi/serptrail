module ApplicationHelper
  def position_sparkline(checks, width: 280, height: 80)
    points = checks.select(&:position).sort_by(&:checked_at)
    return nil if points.size < 2

    positions = points.map(&:position)
    min_pos = positions.min
    max_pos = positions.max
    range = max_pos - min_pos
    range = 1 if range == 0

    padding_x = 8
    padding_top = 8
    padding_bottom = 24
    plot_w = width - (padding_x * 2)
    plot_h = height - padding_top - padding_bottom

    plot_points = points.each_with_index.map do |check, i|
      x = padding_x + (i.to_f / (points.size - 1) * plot_w)
      y = padding_top + ((check.position - min_pos).to_f / range * plot_h)
      { x: x.round(1), y: y.round(1), check: check }
    end

    coords = plot_points.map { |p| "#{p[:x]},#{p[:y]}" }

    tag.svg(width: width, height: height, class: "sparkline", viewBox: "0 0 #{width} #{height}") do
      line = tag.polyline(
        points: coords.join(" "),
        fill: "none",
        stroke: "#2563eb",
        stroke_width: 2,
        stroke_linejoin: "round",
        stroke_linecap: "round"
      )

      dots = safe_join(plot_points.map { |p|
        # Show label below the dot if too close to the top
        label_y = p[:y] > 20 ? p[:y] - 10 : p[:y] + 18

        tag.g(class: "sparkline-point") do
          tag.circle(cx: p[:x], cy: p[:y], r: 16, class: "sparkline-hitarea") +
          tag.circle(cx: p[:x], cy: p[:y], r: 4, class: "sparkline-dot") +
          tag.text(p[:check].position, x: p[:x], y: label_y, class: "sparkline-label")
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

      line + dots + labels
    end
  end
end
