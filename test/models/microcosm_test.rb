require "test_helper"

class MicrocosmTest < ActiveSupport::TestCase
  def test_microcosm_validations
    microcosm_valid({}, true)

    microcosm_valid({ :name => nil }, false)
    microcosm_valid({ :name => "" }, false)
    microcosm_valid({ :name => "a" * 255 }, true)
    microcosm_valid({ :name => "a" * 256 }, false)

    microcosm_valid({ :description => "" }, false)
    microcosm_valid({ :description => "a" * 1023 }, true)
    microcosm_valid({ :description => "a" * 1024 }, false)

    microcosm_valid({ :latitude => 90 }, true)
    microcosm_valid({ :latitude => 90.00001 }, false)
    microcosm_valid({ :latitude => -90 }, true)
    microcosm_valid({ :latitude => -90.00001 }, false)

    microcosm_valid({ :longitude => 180 }, true)
    microcosm_valid({ :longitude => 180.00001 }, false)
    microcosm_valid({ :longitude => -180 }, true)
    microcosm_valid({ :longitude => -180.00001 }, false)

    coords = [:lat, :lon]
    [:min, :max].each do |extremum|
      coords.each do |coord|
        attr = "#{extremum}_#{coord}"
        microcosm_valid({ attr => nil }, false)
        microcosm_valid({ attr => -200 }, false)
        microcosm_valid({ attr => 200 }, false)
      end
    end
  end

  def microcosm_valid(attrs, result)
    mic = build(:microcosm, attrs)
    assert_equal result, mic.valid?, "Expected #{attrs.inspect} to be #{result}"
  end

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

  def test_bbox
    # arrange
    m = create(:microcosm)
    m.min_lat = 10
    m.max_lat = 20
    m.min_lon = 30
    m.max_lon = 40
    # act
    b = m.bbox
    # assert
    assert_equal 10, b.min_lat
    assert_equal 20, b.max_lat
    assert_equal 30, b.min_lon
    assert_equal 40, b.max_lon
  end
end
