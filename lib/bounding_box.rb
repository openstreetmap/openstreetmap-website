class BoundingBox
  def initialize(min_lon, min_lat, max_lon, max_lat)
    @bbox = [min_lon.to_f, min_lat.to_f, max_lon.to_f, max_lat.to_f]
  end

  def self.from_s(s)
    BoundingBox.new(s.split(/,/))
  end

  def min_lon
    @bbox[0]
  end

  def min_lon=(min_lon)
    @bbox[0] = min_lon
  end

  def min_lat
    @bbox[1]
  end

  def min_lat=(min_lat)
    @bbox[1] = min_lat
  end

  def max_lon
    @bbox[2]
  end

  def max_lon=(max_lon)
    @bbox[2] = max_lon
  end

  def max_lat
    @bbox[3]
  end

  def max_lat=(max_lat)
    @bbox[3] = max_lat
  end

  def centre_lon
    (@bbox[0] + @bbox[2]) / 2.0
  end

  def centre_lat
    (@bbox[1] + @bbox[3]) / 2.0
  end

  def width
    @bbox[2] - @bbox[0]
  end

  def height
    @bbox[3] - @bbox[1]
  end

  def slippy_width(zoom)
    width * 256.0 * 2.0 ** zoom / 360.0
  end

  def slippy_height(zoom)
    min = min_lat * Math::PI / 180.0
    max = max_lat * Math::PI / 180.0

    Math.log((Math.tan(max) + 1.0 / Math.cos(max)) / (Math.tan(min) + 1.0 / Math.cos(min))) * 128.0 * 2.0 ** zoom / Math::PI
  end

  def to_s
    return @bbox.join(",")
  end
end
