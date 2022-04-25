require "test_helper"

class CountryTest < ActiveSupport::TestCase
  def test_gb
    gb = Country.find("GB")
    assert_not_nil gb
    assert_equal "GB", gb.code
    assert_in_delta(-8.623555, gb.min_lon)
    assert_in_delta(59.360249, gb.max_lat)
    assert_in_delta(1.759, gb.max_lon)
    assert_in_delta(49.906193, gb.min_lat)
  end

  def test_au
    au = Country.find("AU")
    assert_not_nil au
    assert_equal "AU", au.code
    assert_in_delta(112.911057, au.min_lon)
    assert_in_delta(-10.062805, au.max_lat)
    assert_in_delta(153.639252, au.max_lon)
    assert_in_delta(-43.64397, au.min_lat)
  end

  def test_xx
    xx = Country.find("XX")
    assert_nil xx
  end
end
