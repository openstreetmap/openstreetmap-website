require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  def test_gb
    gb = Country.find_by_code("GB")
    assert_not_nil gb
    assert_equal "GB", gb.code
    assert_equal -8.623555, gb.min_lon
    assert_equal 59.360249, gb.max_lat
    assert_equal 1.759, gb.max_lon
    assert_equal 49.906193, gb.min_lat
  end

  def test_au
    au = Country.find_by_code("AU")
    assert_not_nil au
    assert_equal "AU", au.code
    assert_equal 112.911057, au.min_lon
    assert_equal -10.062805, au.max_lat
    assert_equal 153.639252, au.max_lon
    assert_equal -43.64397, au.min_lat
  end

  def test_xx
    xx = Country.find_by_code("XX")
    assert_nil xx
  end
end
