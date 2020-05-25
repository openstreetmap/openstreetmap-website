require "test_helper"

class MicrocosmTest < ActiveSupport::TestCase
  def test_microcosm_validations
    validate({})

    validate({ :name => nil }, false)
    validate({ :name => "" }, false)
    validate(:name => "a" * 255)
    validate({ :name => "a" * 256 }, false)

    validate({ :description => nil }, false)
    validate({ :description => "" }, false)
    validate(:description => "a" * 1023)
    validate({ :description => "a" * 1024 }, false)

    validate({ :location => nil }, false)
    validate({ :location => "" }, false)
    validate(:location => "a" * 255)
    validate({ :location => "a" * 256 }, false)

    validate(:latitude => 90)
    validate({ :latitude => 90.00001 }, false)
    validate(:latitude => -90)
    validate({ :latitude => -90.00001 }, false)

    validate(:longitude => 180)
    validate({ :longitude => 180.00001 }, false)
    validate(:longitude => -180)
    validate({ :longitude => -180.00001 }, false)

    [:min, :max].each do |extremum|
      [:lat, :lon].each do |coord|
        attr = "#{extremum}_#{coord}"
        validate({ attr => nil }, false)
        validate({ attr => -200 }, false)
        validate({ attr => 200 }, false)
      end
    end
  end

  # There's a possibility to factory this out.  See microcosm_member_test.rb.
  def validate(attrs, result = true)
    object = build(:microcosm, attrs)
    valid = object.valid?
    errors = object.errors.messages
    assert_equal result, valid, "Expected #{attrs.inspect} to be #{result} but #{errors}"
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
    ml = MicrocosmLink.new(:microcosm => m, :site => site_name, :url => site_url_old)
    site_url_new = "http://example2.com"
    # act
    m.set_link(site_name, site_url_new)
    # assert
    ml = MicrocosmLink.find_by(:microcosm_id => m.id, :site => site_name)
    assert_equal ml.url, site_url_new
  end

  def test_member_that_does_exist
    # arrange
    mm = create(:microcosm_member)
    # act
    result = mm.microcosm.member?(mm.user)
    # assert
    assert result
  end

  def test_member_that_does_not_exists
    # arrange
    m = create(:microcosm)
    u = create(:user)
    # act
    result = m.member?(u)
    # assert
    assert !result
  end

  def test_organizer_that_does_exist
    # arrange
    mm = create(:microcosm_member, :organizer)
    # act
    result = mm.microcosm.organizer?(mm.user)
    # assert
    assert result
  end

  def test_organizer_that_does_not_exists
    # arrange
    m = create(:microcosm)
    u = create(:user)
    # act
    result = m.organizer?(u)
    # assert
    assert !result
  end

  def test_organizer_that_is_member
    # arrange
    mm = create(:microcosm_member) # not organizer
    # act
    result = mm.microcosm.organizer?(mm.user)
    # assert
    assert !result
  end

  def test_organizer_that_is_organizer_of_other_microcosm
    # arrange
    mm = create(:microcosm_member, :organizer)
    m = create(:microcosm)
    # act
    result = m.organizer?(mm.user)
    # assert
    assert !result
  end

  def test_organizers_zero
    # arrange
    m = create(:microcosm)
    # act
    o = m.organizers
    # assert
    assert_equal o, []
  end

  def test_organizers_not_zero
    # arrange
    mm = create(:microcosm_member, :organizer)
    # act
    o = mm.microcosm.organizers
    # assert
    assert_equal o, [mm]
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
    assert_equal b.min_lat, 10
    assert_equal b.max_lat, 20
    assert_equal b.min_lon, 30
    assert_equal b.max_lon, 40
  end
end
