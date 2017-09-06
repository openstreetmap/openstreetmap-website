require "test_helper"

class CanAccessHomeTest < Capybara::Rails::TestCase
  def setup
    stub_hostip_requests
  end

  def test_it_works
    visit root_path
    assert page.has_content? "BOpenStreetMap"
  end
end
