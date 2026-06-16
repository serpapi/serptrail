module ChatsHelper
  def markdown(text)
    html = Kramdown::Document.new(text.to_s, hard_wrap: true).to_html
    sanitize(
      html,
      tags: %w[p br strong em a ul ol li code pre blockquote h1 h2 h3 h4 h5 h6 hr],
      attributes: %w[href title]
    )
  end
end
