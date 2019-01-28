module GPX
  class File
    require "libxml"

    include LibXML

    attr_reader :possible_points
    attr_reader :actual_points
    attr_reader :tracksegs

    def initialize(file)
      @file = file
    end

    def points
      @possible_points = 0
      @actual_points = 0
      @tracksegs = 0

      @file.rewind

      reader = XML::Reader.io(@file)

      point = nil

      while reader.read
        if reader.node_type == XML::Reader::TYPE_ELEMENT
          if reader.name == "trkpt"
            point = TrkPt.new(@tracksegs, reader["lat"].to_f, reader["lon"].to_f)
            @possible_points += 1
          elsif reader.name == "ele" && point
            point.altitude = reader.read_string.to_f
          elsif reader.name == "time" && point
            point.timestamp = Time.parse(reader.read_string)
          end
        elsif reader.node_type == XML::Reader::TYPE_END_ELEMENT
          if reader.name == "trkpt" && point && point.valid?
            point.altitude ||= 0
            yield point
            @actual_points += 1
          elsif reader.name == "trkseg"
            @tracksegs += 1
          end
        end
      end
    end

    def picture(min_lat, min_lon, max_lat, max_lon, _num_points)
      # frames = 10
      width = 250
      height = 250
      proj = OSM::Mercator.new(min_lat, min_lon, max_lat, max_lon, width, height)

      # TODO: create animated gif
      # https://github.com/openstreetmap/openstreetmap-website/issues/281
      image = GD2::Image::IndexedColor.new(width, height)

      black = image.palette.allocate(GD2::Color[0, 0, 0])
      white = image.palette.allocate(GD2::Color[255, 255, 255])

      image.draw do |pen|
        pen.color = white
        pen.rectangle(0, 0, width, height, true)
      end

      image.draw do |pen|
        pen.color = black
        pen.anti_aliasing = true
        pen.dont_blend = false

        oldpx = 0.0
        oldpy = 0.0

        first = true

        points do |p|
          px = proj.x(p.longitude)
          py = proj.y(p.latitude)

          pen.line(px, py, oldpx, oldpy) unless first

          first = false
          oldpy = py
          oldpx = px
        end
      end

      image.gif
    end

    def icon(min_lat, min_lon, max_lat, max_lon)
      width = 50
      height = 50
      proj = OSM::Mercator.new(min_lat, min_lon, max_lat, max_lon, width, height)

      image = GD2::Image::IndexedColor.new(width, height)

      black = image.palette.allocate(GD2::Color[0, 0, 0])
      white = image.palette.allocate(GD2::Color[255, 255, 255])

      image.draw do |pen|
        pen.color = white
        pen.rectangle(0, 0, width, height, true)
      end

      image.draw do |pen|
        pen.color = black
        pen.anti_aliasing = true
        pen.dont_blend = false

        oldpx = 0.0
        oldpy = 0.0

        first = true

        points do |p|
          px = proj.x(p.longitude)
          py = proj.y(p.latitude)

          pen.line(px, py, oldpx, oldpy) unless first

          first = false
          oldpy = py
          oldpx = px
        end
      end

      image.gif
    end
  end

  TrkPt = Struct.new(:segment, :latitude, :longitude, :altitude, :timestamp) do
    def valid?
      latitude && longitude && timestamp &&
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    end
  end
end
