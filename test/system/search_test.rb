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
end
