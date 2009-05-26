require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < ActiveSupport::TestCase
  fixtures :countries
  
  test "country count" do
    assert_equal 2, Country.count
  end
end
