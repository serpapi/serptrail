module ApplicationHelper
  def country_flag(code)
    code.to_s.upcase.chars.map { |c| (0x1F1E6 + (c.ord - "A".ord)).chr(Encoding::UTF_8) }.join
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
