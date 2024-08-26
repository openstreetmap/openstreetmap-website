require "test_helper"

class CommunityTest < ActiveSupport::TestCase
  def test_community_validations
    validate({}, true)

    validate({ :name => nil }, false)
    validate({ :name => "" }, false)
    validate({ :name => "a" * 255 }, true)
    validate({ :name => "a" * 256 }, false)

    validate({ :description => nil }, false)
    validate({ :description => "" }, false)
    validate({ :description => "a" * 1023 }, true)
    validate({ :description => "a" * 1024 }, false)

    validate({ :location => nil }, false)
    validate({ :location => "" }, false)
    validate({ :location => "a" * 255 }, true)
    validate({ :location => "a" * 256 }, false)

    validate({ :latitude => 90 }, true)
    validate({ :latitude => 90.00001 }, false)
    validate({ :latitude => -90 }, true)
    validate({ :latitude => -90.00001 }, false)

    validate({ :longitude => 180 }, true)
    validate({ :longitude => 180.00001 }, true)
    validate({ :longitude => -180 }, true)
    validate({ :longitude => -180.00001 }, true)

    [:min, :max].each do |extremum|
      attr = "#{extremum}_lat"
      validate({ attr => nil }, false)
      validate({ attr => -200 }, false)
      validate({ attr => 200 }, false)

      attr = "#{extremum}_lon"
      validate({ attr => nil }, false)
      validate({ attr => -200 }, true)
      validate({ attr => 200 }, true)
    end
  end

  def test_bbox
    m = create(:community)
    m.min_lat = 10
    m.max_lat = 20
    m.min_lon = 30
    m.max_lon = 40

    b = m.bbox

    assert_equal 10, b.min_lat
    assert_equal 20, b.max_lat
    assert_equal 30, b.min_lon
    assert_equal 40, b.max_lon
  end
end
