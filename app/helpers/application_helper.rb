module ApplicationHelper
  def position_sparkline(checks, width: 280, height: 80)
    points = checks.select(&:position).sort_by(&:checked_at)
    return nil if points.size < 2

    positions = points.map(&:position)
    min_pos = positions.min
    max_pos = positions.max
    range = max_pos - min_pos
    range = 1 if range == 0

    padding = 4
    plot_w = width - (padding * 2)
    plot_h = height - (padding * 2)

    coords = points.each_with_index.map do |check, i|
      x = padding + (i.to_f / (points.size - 1) * plot_w)
      # Invert Y: lower position (better rank) = higher on chart
      y = padding + ((check.position - min_pos).to_f / range * plot_h)
      "#{x.round(1)},#{y.round(1)}"
    end

    tag.svg(width: width, height: height, class: "sparkline", viewBox: "0 0 #{width} #{height}") do
      tag.polyline(
        points: coords.join(" "),
        fill: "none",
        stroke: "#2563eb",
        stroke_width: 2,
        stroke_linejoin: "round",
        stroke_linecap: "round"
      )
    end
  end
end
