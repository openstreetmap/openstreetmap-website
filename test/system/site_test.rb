require "application_system_test_case"

class SiteTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit "/"

    assert_selector "h1", :text => "OpenStreetMap"
  end
end
