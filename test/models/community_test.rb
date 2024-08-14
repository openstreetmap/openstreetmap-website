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
    # arrange
    mm = create(:community_member)
    # act
    result = mm.community.member?(mm.user)
    # assert
    assert result
  end

  def test_member_that_does_not_exists
    # arrange
    m = create(:community)
    u = create(:user)
    # act
    result = m.member?(u)
    # assert
    assert_not result
  end

  def test_organizer_that_does_exist
    # arrange
    mm = create(:community_member, :organizer)
    # act
    result = mm.community.organizer?(mm.user)
    # assert
    assert result
  end

  def test_organizer_that_does_not_exists
    # arrange
    m = create(:community)
    u = create(:user)
    # act
    result = m.organizer?(u)
    # assert
    assert_not result
  end

  def test_organizer_that_is_member
    # arrange
    mm = create(:community_member) # not organizer
    # act
    result = mm.community.organizer?(mm.user)
    # assert
    assert_not result
  end

  def test_organizer_that_is_organizer_of_other_community
    # arrange
    mm = create(:community_member, :organizer)
    m = create(:community)
    # act
    result = m.organizer?(mm.user)
    # assert
    assert_not result
  end

  def test_organizers_zero
    # arrange
    m = create(:community)
    # act
    o = m.organizers
    # assert
    assert_empty o
  end

  def test_organizers_not_zero
    # arrange
    mm = create(:community_member, :organizer)
    # act
    o = mm.community.organizers
    # assert
    assert_equal o, [mm]
  end
end
