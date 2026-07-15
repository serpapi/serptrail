module ChatsHelper
  def markdown(text)
    html = Kramdown::Document.new(escape_pipes_in_link_text(text.to_s), hard_wrap: true, input: "GFM").to_html
    sanitized_html = sanitize(
      html,
      tags: %w[p br strong em a ul ol li code pre blockquote h1 h2 h3 h4 h5 h6 hr],
      attributes: %w[href title]
    )
    open_markdown_links_in_top_frame(sanitized_html)
  end

  private

  # Pipes in link text (e.g. product titles like "iPhone 13 | 128GB | Black")
  # make Kramdown parse the line as a table, leaving the link unconverted.
  def escape_pipes_in_link_text(text)
    text.gsub(/\[([^\]]*)\]\(([^)\s]*)\)/) do
      label, url = $1, $2
      "[#{label.gsub("|") { "\\|" }}](#{url})"
    end
  end

  def open_markdown_links_in_top_frame(html)
    fragment = Loofah.fragment(html.to_s)

    fragment.css("a[href]").each do |link|
      link["data-turbo-frame"] = "_top"
    end

    fragment.to_s.html_safe
  end
end
