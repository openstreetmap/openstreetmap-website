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

  def test_member_that_does_exist
    mm = create(:community_member)

    result = mm.community.member?(mm.user)

    assert result
  end

  def test_member_that_does_not_exists
    m = create(:community)
    u = create(:user)

    result = m.member?(u)

    assert_not result
  end

  def test_organizer_that_does_exist
    mm = create(:community_member, :organizer)

    result = mm.community.organizer?(mm.user)

    assert result
  end

  def test_organizer_that_does_not_exists
    m = create(:community)
    u = create(:user)

    result = m.organizer?(u)

    assert_not result
  end

  def test_organizer_that_is_member
    mm = create(:community_member) # not organizer

    result = mm.community.organizer?(mm.user)

    assert_not result
  end

  def test_organizer_that_is_organizer_of_other_community
    mm = create(:community_member, :organizer)
    m = create(:community)

    result = m.organizer?(mm.user)

    assert_not result
  end

  def test_organizers_zero
    m = create(:community)

    o = m.organizers

    assert_empty o
  end

  def test_organizers_not_zero
    mm = create(:community_member, :organizer)

    o = mm.community.organizers

    assert_equal o, [mm]
  end
end
