require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  test "click on 'where is this' sets search input value" do
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)

    visit "/#map=7/1.234/6.789"

    assert_field "Search", :with => ""
    click_on "Where is this?"
    assert_field "Search", :with => "1.234, 6.789"
  end

  test "query search link sets search input value" do
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)

    visit search_path(:query => "2.341, 7.896")

    assert_field "Search", :with => "2.341, 7.896"
  end

  test "latlon search link sets search input value" do
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)

    visit search_path(:lat => "4.321", :lon => "9.876")

    assert_field "Search", :with => "4.321, 9.876"
  end
end
