require "test_helper"

class MicrocosmTest < ActiveSupport::TestCase
  def test_set_link_that_does_not_exist
    # arrange
    site_name = "site_name"
    site_url = "http://example.com"
    m = create(:microcosm)
    # act
    m.set_link(site_name, site_url)
    # assert
    ml = MicrocosmLink.find_by(:microcosm_id => m.id, :site => site_name)
    assert_equal ml.url, site_url
  end

  def test_set_link_that_does_exist
    # arrange
    m = create(:microcosm)
    site_name = "site_name"
    site_url_old = "http://example1.com"
    MicrocosmLink.new(:microcosm => m, :site => site_name, :url => site_url_old)
    site_url_new = "http://example2.com"
    # act
    m.set_link(site_name, site_url_new)
    # assert
    ml = MicrocosmLink.find_by(:microcosm_id => m.id, :site => site_name)
    assert_equal ml.url, site_url_new
  end
end
