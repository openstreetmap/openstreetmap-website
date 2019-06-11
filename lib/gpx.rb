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

    def parse_file(reader)
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

    def points(&block)
      return enum_for(:points) unless block_given?

      @possible_points = 0
      @actual_points = 0
      @tracksegs = 0

      begin
        Archive::Reader.open_filename(@file).each_entry_with_data do |_entry, data|
          parse_file(XML::Reader.string(data), &block)
        end
      rescue Archive::Error
        io = ::File.open(@file)

        case MimeMagic.by_magic(io).type
        when "application/gzip" then io = Zlib::GzipReader.open(@file)
        when "application/x-bzip" then io = Bzip2::FFI::Reader.open(@file)
        end

        parse_file(XML::Reader.io(io), &block)
      end
    end

    def picture(min_lat, min_lon, max_lat, max_lon, num_points)
      nframes = 10
      width = 250
      height = 250
      delay = 50

      points_per_frame = (num_points.to_f / nframes).ceil

      proj = OSM::Mercator.new(min_lat, min_lon, max_lat, max_lon, width, height)

      frames = []

      (0...nframes).each do |n|
        frames[n] = GD2::Image::IndexedColor.new(width, height)
        black = frames[n].palette.allocate(GD2::Color[0, 0, 0])
        white = frames[n].palette.allocate(GD2::Color[255, 255, 255])
        grey = frames[n].palette.allocate(GD2::Color[187, 187, 187])

        frames[n].draw do |pen|
          pen.color = white
          pen.rectangle(0, 0, width, height, true)
        end

        frames[n].draw do |pen|
          pen.color = black
          pen.anti_aliasing = true
          pen.dont_blend = false

          oldpx = 0.0
          oldpy = 0.0

          first = true

          points.each_with_index do |p, pt|
            px = proj.x(p.longitude)
            py = proj.y(p.latitude)

            if (pt >= (points_per_frame * n)) && (pt <= (points_per_frame * (n + 1)))
              pen.thickness = 3
              pen.color = black
            else
              pen.thickness = 1
              pen.color = grey
            end

            pen.line(px, py, oldpx, oldpy) unless first
            first = false
            oldpy = py
            oldpx = px
          end
        end
      end

      image = GD2::AnimatedGif.new
      image.add(frames.first)
      frames.each do |frame|
        image.add(frame, :delay => delay)
      end
      image.end

      output = StringIO.new
      image.export(output)
      output.read
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
