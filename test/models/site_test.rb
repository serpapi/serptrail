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
end
