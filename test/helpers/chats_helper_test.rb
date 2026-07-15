require "test_helper"

class ChatsHelperTest < ActionView::TestCase
  test "markdown converts links and opens them in the top frame" do
    html = markdown("See [SerpTrail](https://example.com/serptrail).")

    assert_includes html, %(<a href="https://example.com/serptrail" data-turbo-frame="_top">SerpTrail</a>)
  end

  test "markdown converts links whose text contains pipes" do
    html = markdown("- **Title:** [iPhone 13 | 128GB | Black](https://example.com/item)")

    assert_includes html, %(<a href="https://example.com/item" data-turbo-frame="_top">iPhone 13 | 128GB | Black</a>)
    assert_not_includes html, "[iPhone 13"
  end
end
