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
          elsif reader.name == "ele" and point
            point.altitude = reader.read_string.to_f
          elsif reader.name == "time" and point
            point.timestamp = DateTime.parse(reader.read_string)
          end
        elsif reader.node_type == XML::Reader::TYPE_END_ELEMENT
          if reader.name == "trkpt" and point and point.valid?
            point.altitude ||= 0
            yield point
            @actual_points += 1
          elsif reader.name == "trkseg"
            @tracksegs += 1
          end
        end
      end
    end

    def picture(min_lat, min_lon, max_lat, max_lon, num_points)
      frames = 10
      width = 250
      height = 250
      proj = OSM::Mercator.new(min_lat, min_lon, max_lat, max_lon, width, height)

      linegc = Magick::Draw.new
      linegc.stroke_linejoin('miter')
      linegc.stroke_width(1)
      linegc.stroke('#BBBBBB')
      linegc.fill('#BBBBBB')

      highlightgc = Magick::Draw.new
      highlightgc.stroke_linejoin('miter')
      highlightgc.stroke_width(3)
      highlightgc.stroke('#000000')
      highlightgc.fill('#000000')

      images = []

      frames.times do
        image = Magick::Image.new(width, height) do |image|
          image.background_color = 'white'
          image.format = 'GIF'
        end

        images << image
      end

      oldpx = 0.0
      oldpy = 0.0

      first = true

      m = 0
      mm = 0
      points do |p|
        px = proj.x(p.longitude)
        py = proj.y(p.latitude)

        if m > 0
          frames.times do |n|
            if n == mm
              gc = highlightgc.dup
            else
              gc = linegc.dup
            end

            gc.line(px, py, oldpx, oldpy)

            gc.draw(images[n])
          end
        end

        m += 1
        if m > num_points.to_f / frames.to_f * (mm+1)
          mm += 1
        end

        oldpy = py
        oldpx = px
      end

      il = Magick::ImageList.new

      images.each do |f|
        il << f
      end

      il.delay = 50
      il.format = 'GIF'

      return il.to_blob
    end

    def icon(min_lat, min_lon, max_lat, max_lon)
      width = 50
      height = 50
      proj = OSM::Mercator.new(min_lat, min_lon, max_lat, max_lon, width, height)

      gc = Magick::Draw.new
      gc.stroke_linejoin('miter')
      gc.stroke_width(1)
      gc.stroke('#000000')
      gc.fill('#000000')

      image = Magick::Image.new(width, height) do |image|
        image.background_color = 'white'
        image.format = 'GIF'
      end

      oldpx = 0.0
      oldpy = 0.0

      first = true

      points do |p|
        px = proj.x(p.longitude)
        py = proj.y(p.latitude)

        gc.dup.line(px, py, oldpx, oldpy).draw(image) unless first

        first = false
        oldpy = py
        oldpx = px
      end

      return image.to_blob
    end
  end

private

  class TrkPt < Struct.new(:segment, :latitude, :longitude, :altitude, :timestamp)
    def valid?
      self.latitude and self.longitude and self.timestamp and
      self.latitude >= -90 and self.latitude <= 90 and
      self.longitude >= -180 and self.longitude <= 180
    end
  end
end
