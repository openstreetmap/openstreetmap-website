require File.dirname(__FILE__) + '/../test_helper'

class ExportTest < ActionController::IntegrationTest
  include Capybara::DSL

  setup do
    Capybara.current_driver = :selenium
  end

  teardown do
    Capybara.use_default_driver
  end

  def test_export_from_index_page
    visit("/")
    click_link("Export")
    assert_equal "Export", page.find("#sidebar_title").text
  end

  def test_export_from_browse_page
    visit("/browse/changesets")
    click_link("Export")
    assert page.has_css?("#map")
    assert_equal "Export", page.find("#sidebar_title").text
  end
end
