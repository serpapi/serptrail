require "test_helper"

class SiteTest < ActiveSupport::TestCase
  test "valid site" do
    site = Site.new(name: "Test", domain: "test.com")
    assert site.valid?
  end

  test "requires name" do
    site = Site.new(domain: "test.com")
    assert_not site.valid?
    assert_includes site.errors[:name], "can't be blank"
  end

  test "requires domain" do
    site = Site.new(name: "Test")
    assert_not site.valid?
    assert_includes site.errors[:domain], "can't be blank"
  end

  test "domain must be unique" do
    site = Site.new(name: "Duplicate", domain: "example.com")
    assert_not site.valid?
    assert_includes site.errors[:domain], "has already been taken"
  end

  test "normalizes domain by stripping protocol" do
    site = Site.new(name: "Test", domain: "https://Example.COM/")
    assert_equal "example.com", site.domain
  end

  test "normalizes domain by lowercasing and removing trailing slash" do
    site = Site.new(name: "Test", domain: "HTTP://SITE.COM/")
    assert_equal "site.com", site.domain
  end

  test "tracking_enabled defaults to true" do
    site = Site.create!(name: "Test", domain: "new.com")
    assert site.tracking_enabled?
  end

  test "rejects invalid domain formats" do
    invalid_domains = [
      "foo bar.com",
      "-foo.com",
      "foo-.com",
      "foo..com",
      ".foo.com",
      "foo.com.",
      "foo",
      "foo.c",
      "foo.com:8080",
      "foo.com/path"
    ]

    invalid_domains.each do |domain|
      site = Site.new(name: "Test", domain: domain)
      assert_not site.valid?, "expected #{domain.inspect} to be invalid"
      assert_includes site.errors[:domain], "must be a valid domain"
    end
  end

  test "accepts valid domain formats" do
    valid_domains = [ "foo.com", "sub.foo.com", "foo-bar.co.uk", "xn--example.com", "a.photography" ]

    valid_domains.each do |domain|
      site = Site.new(name: "Test", domain: domain)
      assert site.valid?, "expected #{domain.inspect} to be valid, got #{site.errors.full_messages}"
    end
  end
end
