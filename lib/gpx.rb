# frozen_string_literal: true

module GPX
  class File
    include LibXML

    attr_reader :possible_points, :actual_points, :tracksegs

    def initialize(file, options = {})
      @file = file
      @maximum_points = options[:maximum_points] || Float::INFINITY
    end

    def parse_file(reader)
      point = nil

      while reader.read
        case reader.node_type
        when XML::Reader::TYPE_ELEMENT
          if reader.name == "trkpt"
            point = TrkPt.new(@tracksegs, reader["lat"].to_f, reader["lon"].to_f)
            @possible_points += 1
            raise FileTooBigError if @possible_points > @maximum_points
          elsif reader.name == "ele" && point
            point.altitude = reader.read_string.to_f
          elsif reader.name == "time" && point
            point.timestamp = Time.parse(reader.read_string).utc
          end
        when XML::Reader::TYPE_END_ELEMENT
          if reader.name == "trkpt" && point&.valid?
            point.altitude ||= 0
            yield point
            @actual_points += 1
            @lats << point.latitude
            @lons << point.longitude
          elsif reader.name == "trkseg"
            @tracksegs += 1
          end
        end
      end
    end

    # Parse a KML file, handling two track formats:
    #
    # 1. <Placemark><LineString><coordinates> (e.g. Traccar exports)
    #    Coordinates are space-separated "lon,lat,alt" tuples with no per-point
    #    timestamps.  We assign synthetic 1-second-apart timestamps starting
    #    from a base time extracted from the Placemark <name> when possible, or
    #    falling back to Unix epoch.
    #
    # 2. Google Earth extended-data <gx:Track> elements that pair a <when>
    #    timestamp with a <gx:coord> "lon lat alt" value.
    #
    # Both formats can coexist in the same KML document.
    def parse_kml_file(reader, &block) # rubocop:disable Metrics/MethodLength
      in_linestring   = false
      in_gx_track     = false
      in_placemark    = false
      placemark_name  = nil
      gx_whens        = []
      gx_coords       = []

      while reader.read
        case reader.node_type
        when XML::Reader::TYPE_ELEMENT
          case reader.name
          when "Placemark"
            in_placemark   = true
            placemark_name = nil
          when "name"
            if in_placemark && !in_linestring && !in_gx_track
              placemark_name = reader.read_string
            end
          when "LineString"
            in_linestring = true
          when "coordinates"
            if in_linestring
              raw = reader.read_string
              base_time = parse_kml_placemark_time(placemark_name)
              emit_linestring_coords(raw, base_time, &block)
              in_linestring = false
            end
          when "gx:Track"
            in_gx_track = true
            gx_whens    = []
            gx_coords   = []
          when "when"
            if in_gx_track
              gx_whens << reader.read_string
            end
          when "gx:coord"
            if in_gx_track
              gx_coords << reader.read_string
            end
          end

        when XML::Reader::TYPE_END_ELEMENT
          case reader.name
          when "Placemark"
            in_placemark  = false
            placemark_name = nil
          when "LineString"
            in_linestring = false
          when "gx:Track"
            emit_gx_track_coords(gx_whens, gx_coords, &block)
            @tracksegs += 1
            in_gx_track = false
            gx_whens    = []
            gx_coords   = []
          end
        end
      end
    end

    def points(&block)
      return enum_for(:points) unless block

      @possible_points = 0
      @actual_points = 0
      @tracksegs = 0
      @lats = []
      @lons = []

      begin
        Archive::Reader.open_filename(@file).each_entry_with_data do |entry, data|
          if entry.regular?
            if kml_data?(data)
              parse_kml_file(XML::Reader.string(data), &block)
            else
              parse_file(XML::Reader.string(data), &block)
            end
          end
        end
      rescue Archive::Error
        io = ::File.open(@file)

        case Marcel::MimeType.for(io)
        when "application/gzip" then io = Zlib::GzipReader.open(@file)
        when "application/x-bzip2" then io = Bzip2::FFI::Reader.open(@file)
        end

        if kml_file?(@file)
          parse_kml_file(XML::Reader.io(io, :options => XML::Parser::Options::NOERROR), &block)
        else
          parse_file(XML::Reader.io(io, :options => XML::Parser::Options::NOERROR), &block)
        end
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

          @actual_points.times do |pt|
            px = proj.x @lons[pt]
            py = proj.y @lats[pt]

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
      output
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

        @actual_points.times do |pt|
          px = proj.x @lons[pt]
          py = proj.y @lats[pt]

          pen.line(px, py, oldpx, oldpy) unless first

          first = false
          oldpy = py
          oldpx = px
        end
      end

      StringIO.new(image.gif)
    end

    private

    # Returns true when the raw string content of a file looks like KML.
    def kml_data?(data)
      head = data.byteslice(0, 1024) || ""
      head.include?("http://www.opengis.net/kml") ||
        head.include?("<kml") ||
        head.include?("<KML")
    end

    # Returns true when the file at +path+ looks like KML by peeking at its
    # first 1 KB (works for plain, gz, and bz2 files because we only look at
    # the already-decompressed io that the caller opened).
    def kml_file?(path)
      head = ::File.read(path, 1024) || ""
      head.include?("http://www.opengis.net/kml") ||
        head.include?("<kml") ||
        head.include?("<KML")
    rescue StandardError
      false
    end

    # Try to extract a UTC base time from a KML Placemark name such as:
    #   "2026-03-09 22:00 - 2026-03-10 21:59"
    # Returns nil when the name cannot be parsed.
    def parse_kml_placemark_time(name)
      return nil if name.nil?

      # Match the first ISO-8601-ish date/time in the string
      if (m = name.match(/(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2})?)/))
        Time.parse(m[1]).utc
      end
    rescue ArgumentError, TypeError
      nil
    end

    # Yield TrkPt objects for every valid "lon,lat[,alt]" tuple found in the
    # space-separated +raw+ coordinate string (KML LineString format).
    # When no per-point timestamp is available we assign synthetic ones that
    # are 1 second apart starting from +base_time+ (or Unix epoch).
    def emit_linestring_coords(raw, base_time)
      base_time ||= Time.utc(1970, 1, 1)
      offset = 0

      raw.split(/\s+/).each do |tuple|
        next if tuple.strip.empty?

        parts = tuple.split(",")
        next unless parts.length >= 2

        lon = parts[0].to_f
        lat = parts[1].to_f
        alt = parts[2]&.to_f || 0.0

        point = TrkPt.new(@tracksegs, lat, lon)
        point.altitude  = alt
        point.timestamp = base_time + offset

        @possible_points += 1
        raise FileTooBigError if @possible_points > @maximum_points

        if point.valid?
          yield point
          @actual_points += 1
          @lats << point.latitude
          @lons << point.longitude
          offset += 1
        end
      end

      # Treat the whole LineString as one track segment
      @tracksegs += 1
    end

    # Yield TrkPt objects from a <gx:Track> block given parallel arrays of
    # ISO-8601 timestamp strings (+whens+) and "lon lat [alt]" coord strings
    # (+coords+).  Unpaired or un-parseable entries are skipped.
    def emit_gx_track_coords(whens, coords)
      whens.zip(coords).each do |when_str, coord_str|
        next if when_str.nil? || coord_str.nil?

        parts = coord_str.strip.split(/\s+/)
        next unless parts.length >= 2

        lon = parts[0].to_f
        lat = parts[1].to_f
        alt = parts[2]&.to_f || 0.0

        timestamp = begin
          Time.parse(when_str).utc
        rescue ArgumentError, TypeError
          next
        end

        point = TrkPt.new(@tracksegs, lat, lon)
        point.altitude  = alt
        point.timestamp = timestamp

        @possible_points += 1
        raise FileTooBigError if @possible_points > @maximum_points

        if point.valid?
          yield point
          @actual_points += 1
          @lats << point.latitude
          @lons << point.longitude
        end
      end
    end
  end

  TrkPt = Struct.new(:segment, :latitude, :longitude, :altitude, :timestamp) do
    def valid?
      latitude && longitude && timestamp &&
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    end
  end

  class FileTooBigError < RuntimeError
    def initialise
      super("GPX File contains too many points")
    end
  end
end
