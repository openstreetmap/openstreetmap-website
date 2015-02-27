require "test_helper"

class BoundingBoxTest < ActiveSupport::TestCase
  def setup
    @size_error_message = "The maximum bbox size is 0.25, and your request was too large. Either request a smaller area, or use planet.osm"
    @malformed_error_message = "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat"
    @lon_order_error_message = "The minimum longitude must be less than the maximum longitude, but it wasn't"
    @lat_order_error_message = "The minimum latitude must be less than the maximum latitude, but it wasn't"
    @bbox_out_of_limits_error_message = "The latitudes must be between -90.0 and 90.0, and longitudes between -180.0 and 180.0"
    @nil_error_message = "Should not contain nil"

    @bbox_from_nils = BoundingBox.new(nil, nil, nil, nil)
    @bbox_expand = BoundingBox.new(0, 0, 0, 0)
    @bbox_expand_ten = BoundingBox.new(10, 10, 10, 10)
    @bbox_expand_minus_two = BoundingBox.new(-2, -2, -2, -2)
    @bbox_from_string = BoundingBox.from_s("1,2,3,4")
    @min_lon = 1.0
    @min_lat = 2.0
    @max_lon = 3.0
    @max_lat = 4.0

    @bad_positive_boundary_bbox  = %w(181,91,0,0 0,0,181,91)
    @bad_negative_boundary_bbox  = %w(-181,-91,0,0 0,0,-181,-91)
    @bad_big_bbox       = %w(-0.1,-0.1,1.1,1.1  10,10,11,11)
    @bad_malformed_bbox = %w(-0.1  hello 10N2W10.1N2.1W)
    @bad_lat_mixed_bbox  = %w(0,0.1,0.1,0  -0.1,80,0.1,70  0.24,54.34,0.25,54.33)
    @bad_lon_mixed_bbox  = %w(80,-0.1,70,0.1  54.34,0.24,54.33,0.25)
    @bad_limit_bbox = %w(-180.1,-90,180,90 -180,-90.1,180,90 -180,-90,180.1,90 -180,-90,180,90.1)
    @good_bbox         = %w(-0.1,-0.1,0.1,0.1  51.1,-0.1,51.2,0 -0.1,%20-0.1,%200.1,%200.1
                            -0.1edcd,-0.1d,0.1,0.1  -0.1E,-0.1E,0.1S,0.1N S0.1,W0.1,N0.1,E0.1)

    @expand_min_lon_array = %w(2,10,10,10 1,10,10,10 0,10,10,10 -1,10,10,10 -2,10,10,10 -8,10,10,10)
    @expand_min_lat_array = %w(10,2,10,10 10,1,10,10 10,0,10,10 10,-1,10,10 10,-2,10,10 10,-8,10,10)
    @expand_max_lon_array = %w(-2,-2,-1,-2 -2,-2,0,-2 -2,-2,1,-2 -2,-2,2,-2)
    @expand_max_lat_array = %w(-2,-2,-2,-1 -2,-2,-2,0 -2,-2,-2,1 -2,-2,-2,2)
    @expand_min_lon_margin_response = [[2, 10, 10, 10], [-7, 10, 10, 10], [-7, 10, 10, 10], [-7, 10, 10, 10], [-7, 10, 10, 10], [-25, 10, 10, 10]]
    @expand_min_lat_margin_response = [[10, 2, 10, 10], [10, -7, 10, 10], [10, -7, 10, 10], [10, -7, 10, 10], [10, -7, 10, 10], [10, -25, 10, 10]]
    @expand_max_lon_margin_response = [[-2, -2, -1, -2], [-2, -2, 1, -2], [-2, -2, 1, -2], [-2, -2, 5, -2]]
    @expand_max_lat_margin_response = [[-2, -2, -2, -1], [-2, -2, -2, 1], [-2, -2, -2, 1], [-2, -2, -2, 5]]
  end

  def test_good_bbox_from_string
    @good_bbox.each do |string|
      bbox = BoundingBox.from_s(string)
      array = string.split(",").collect(&:to_f)
      check_bbox(bbox, array)
    end
  end

  def test_bbox_from_s_malformed
    @bad_malformed_bbox.each do |bbox_string|
      bbox = BoundingBox.from_s(bbox_string)
      assert_nil bbox
    end
  end

  def test_good_bbox_from_params
    @good_bbox.each do |string|
      bbox = BoundingBox.from_bbox_params(:bbox => string)
      array = string.split(",").collect(&:to_f)
      check_bbox(bbox, array)
    end
  end

  def test_good_bbox_from_lon_lat_params
    @good_bbox.each do |string|
      array = string.split(",")
      bbox = BoundingBox.from_lon_lat_params(:minlon => array[0], :minlat => array[1], :maxlon => array[2], :maxlat => array[3])
      check_bbox(bbox, array.collect(&:to_f))
    end
  end

  def test_bbox_from_params_malformed
    @bad_malformed_bbox.each do |bbox_string|
      exception = assert_raise(OSM::APIBadUserInput) { BoundingBox.from_bbox_params(:bbox => bbox_string) }
      assert_equal(@malformed_error_message, exception.message)
    end
  end

  def test_good_bbox_from_new
    @good_bbox.each do |string|
      array = string.split(",")
      bbox = BoundingBox.new(array[0], array[1], array[2], array[3])
      check_bbox(bbox, array.collect(&:to_f))
    end
  end

  def test_creation_from_new_with_nils
    check_bbox(@bbox_from_nils, [nil, nil, nil, nil])
  end

  def test_expand_min_lon_boundary
    @bbox_expand.expand!(BoundingBox.new(-1810000000, 0, 0, 0))
    check_expand(@bbox_expand, "-1800000000,0,0,0")
  end

  def test_expand_min_lat_boundary
    @bbox_expand.expand!(BoundingBox.new(0, -910000000, 0, 0))
    check_expand(@bbox_expand, "0,-900000000,0,0")
  end

  def test_expand_max_lon_boundary
    @bbox_expand.expand!(BoundingBox.new(0, 0, 1810000000, 0))
    check_expand(@bbox_expand, "0,0,1800000000,0")
  end

  def test_expand_max_lat_boundary
    @bbox_expand.expand!(BoundingBox.new(0, 0, 0, 910000000))
    check_expand(@bbox_expand, "0,0,0,900000000")
  end

  def test_expand_min_lon_without_margin
    @expand_min_lon_array.each { |array_string| check_expand(@bbox_expand_ten, array_string) }
  end

  def test_expand_min_lon_with_margin
    @expand_min_lon_array.each_with_index do |array_string, index|
      check_expand(@bbox_expand_ten, array_string, 1, @expand_min_lon_margin_response[index])
    end
  end

  def test_expand_min_lat_without_margin
    @expand_min_lat_array.each { |array_string| check_expand(@bbox_expand_ten, array_string) }
  end

  def test_expand_min_lat_with_margin
    @expand_min_lat_array.each_with_index do |array_string, index|
      check_expand(@bbox_expand_ten, array_string, 1, @expand_min_lat_margin_response[index])
    end
  end

  def test_expand_max_lon_without_margin
    @expand_max_lon_array.each { |array_string| check_expand(@bbox_expand_minus_two, array_string) }
  end

  def test_expand_max_lon_with_margin
    @expand_max_lon_array.each_with_index do |array_string, index|
      check_expand(@bbox_expand_minus_two, array_string, 1, @expand_max_lon_margin_response[index])
    end
  end

  def test_expand_max_lat_without_margin
    @expand_max_lat_array.each { |array_string| check_expand(@bbox_expand_minus_two, array_string) }
  end

  def test_expand_max_lat_with_margin
    @expand_max_lat_array.each_with_index do |array_string, index|
      check_expand(@bbox_expand_minus_two, array_string, 1, @expand_max_lat_margin_response[index])
    end
  end

  def test_good_bbox_boundaries
    @good_bbox.each do |bbox_string|
      assert_nothing_raised(OSM::APIBadBoundingBox) { BoundingBox.from_s(bbox_string).check_boundaries }
    end
  end

  def test_from_params_with_positive_out_of_boundary
    @bad_positive_boundary_bbox.each do |bbox_string|
      bbox = BoundingBox.from_bbox_params(:bbox => bbox_string)
      array = bbox.to_a
      assert_equal 180, [array[0], array[2]].max
      assert_equal 90, [array[1], array[3]].max
    end
  end

  def test_from_params_with_negative_out_of_boundary
    @bad_negative_boundary_bbox.each do |bbox_string|
      bbox = BoundingBox.from_bbox_params(:bbox => bbox_string)
      array = bbox.to_a
      assert_equal -180, [array[0], array[2]].min
      assert_equal -90, [array[1], array[3]].min
    end
  end

  def test_boundaries_mixed_lon
    @bad_lon_mixed_bbox.each do |bbox_string|
      exception = assert_raise(OSM::APIBadBoundingBox) { BoundingBox.from_s(bbox_string).check_boundaries }
      assert_equal(@lon_order_error_message, exception.message)
    end
  end

  def test_boundaries_mixed_lat
    @bad_lat_mixed_bbox.each do |bbox_string|
      exception = assert_raise(OSM::APIBadBoundingBox) { BoundingBox.from_s(bbox_string).check_boundaries }
      assert_equal(@lat_order_error_message, exception.message)
    end
  end

  def test_boundaries_out_of_limits
    @bad_limit_bbox.each do |bbox_string|
      exception = assert_raise(OSM::APIBadBoundingBox) { BoundingBox.from_s(bbox_string).check_boundaries }
      assert_equal(@bbox_out_of_limits_error_message, exception.message)
    end
  end

  def test_good_bbox_size
    @good_bbox.each do |bbox_string|
      assert_nothing_raised(OSM::APIBadBoundingBox) { BoundingBox.from_s(bbox_string).check_size }
    end
  end

  def test_size_to_big
    @bad_big_bbox.each do |bbox_string|
      bbox = nil
      assert_nothing_raised(OSM::APIBadBoundingBox) { bbox = BoundingBox.from_bbox_params(:bbox => bbox_string).check_boundaries }
      exception = assert_raise(OSM::APIBadBoundingBox) { bbox.check_size }
      assert_equal(@size_error_message, exception.message)
    end
  end

  def test_good_bbox_area
    @good_bbox.each do |string|
      bbox = BoundingBox.from_s(string)
      array = string.split(",")
      assert_equal ((array[2].to_f - array[0].to_f) * (array[3].to_f - array[1].to_f)), bbox.area
    end
  end

  def test_nil_bbox_area
    assert_equal 0, @bbox_from_nils.area
  end

  def test_complete
    assert !@bbox_from_nils.complete?, "should contain a nil"
    assert @bbox_from_string.complete?, "should not contain a nil"
  end

  def test_centre_lon
    @good_bbox.each do |bbox_string|
      array = bbox_string.split(",")
      assert_equal ((array[0].to_f + array[2].to_f) / 2.0), BoundingBox.from_s(bbox_string).centre_lon
    end
  end

  def test_centre_lat
    @good_bbox.each do |bbox_string|
      array = bbox_string.split(",")
      assert_equal ((array[1].to_f + array[3].to_f) / 2.0), BoundingBox.from_s(bbox_string).centre_lat
    end
  end

  def test_width
    @good_bbox.each do |bbox_string|
      array = bbox_string.split(",")
      assert_equal (array[2].to_f - array[0].to_f), BoundingBox.from_s(bbox_string).width
    end
  end

  def test_height
    @good_bbox.each do |bbox_string|
      array = bbox_string.split(",")
      assert_equal (array[3].to_f - array[1].to_f), BoundingBox.from_s(bbox_string).height
    end
  end

  def test_slippy_width
    assert_in_delta 5.68888888888889, @bbox_from_string.slippy_width(2), 0.000000000000001
  end

  def test_slippy_height
    assert_in_delta 5.69698684268433, @bbox_from_string.slippy_height(2), 0.000000000000001
  end

  def test_add_bounds_to_no_underscore
    bounds = @bbox_from_string.add_bounds_to({})
    assert_equal 4, bounds.size
    assert_equal @min_lon.to_s, bounds["minlon"]
    assert_equal @min_lat.to_s, bounds["minlat"]
    assert_equal @max_lon.to_s, bounds["maxlon"]
    assert_equal @max_lat.to_s, bounds["maxlat"]
  end

  def test_add_bounds_to_with_underscore
    bounds = @bbox_from_string.add_bounds_to({}, "_")
    assert_equal 4, bounds.size
    assert_equal @min_lon.to_s, bounds["min_lon"]
    assert_equal @min_lat.to_s, bounds["min_lat"]
    assert_equal @max_lon.to_s, bounds["max_lon"]
    assert_equal @max_lat.to_s, bounds["max_lat"]
  end

  def test_to_scaled
    bbox = @bbox_from_string.to_scaled
    assert_equal @min_lon * GeoRecord::SCALE, bbox.min_lon
    assert_equal @min_lat * GeoRecord::SCALE, bbox.min_lat
    assert_equal @max_lon * GeoRecord::SCALE, bbox.max_lon
    assert_equal @max_lat * GeoRecord::SCALE, bbox.max_lat
  end

  def test_to_unscaled
    scale = GeoRecord::SCALE
    bbox = BoundingBox.new(1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale).to_unscaled
    check_bbox(bbox, [@min_lon, @min_lat, @max_lon, @max_lat])
  end

  def test_to_a
    assert_equal [1.0, 2.0, 3.0, 4.0], @bbox_from_string.to_a
  end

  def test_to_string
    assert_equal "#{@min_lon},#{@min_lat},#{@max_lon},#{@max_lat}", @bbox_from_string.to_s
  end

  private

  def check_expand(bbox, array_string, margin = 0, result = nil)
    array = array_string.split(",").collect(&:to_f)
    result = array unless result
    bbox.expand!(BoundingBox.new(array[0], array[1], array[2], array[3]), margin)
    check_bbox(bbox, result)
  end

  def check_bbox(bbox, result)
    assert_equal result[0], bbox.min_lon, "min_lon"
    assert_equal result[1], bbox.min_lat, "min_lat"
    assert_equal result[2], bbox.max_lon, "max_lon"
    assert_equal result[3], bbox.max_lat, "max_lat"
  end
end
