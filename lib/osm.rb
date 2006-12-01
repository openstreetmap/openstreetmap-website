module OSM

  # This piece of magic reads a GPX with SAX and spits out
  # lat/lng and stuff
  #
  # This would print every latitude value:
  #
  # gpx = OSM:GPXImporter.new('somefile.gpx')
  # gpx.points {|p| puts p['latitude']}
  
  require 'time'
  require 'rexml/parsers/sax2parser'
  require 'rexml/text'

  class GPXImporter
    attr_reader :possible_points
    attr_reader :actual_points
    attr_reader :tracksegs

    def initialize(filename)
      @filename = filename
      @possible_points = 0
      @actual_points = 0
      @tracksegs = 0
    end

    def points
      file = File.new(@filename)
      parser = REXML::Parsers::SAX2Parser.new( file )

      lat = -1
      lon = -1
      ele = -1
      date = Time.now();
      gotlatlon = false
      gotele = false
      gotdate = false

      parser.listen( :start_element,  %w{ trkpt }) do |uri,localname,qname,attributes| 
        lat = attributes['lat'].to_f
        lon = attributes['lon'].to_f
        gotlatlon = true
        @possible_points += 1
      end

      parser.listen( :characters, %w{ ele } ) do |text|
        ele = text
        gotele = true
      end

      parser.listen( :characters, %w{ time } ) do |text|
        if text && text != ''
          date = Time.parse(text)
          gotdate = true
        end
      end

      parser.listen( :end_element, %w{ trkseg } ) do |uri, localname, qname|
        @tracksegs += 1
      end

      parser.listen( :end_element, %w{ trkpt } ) do |uri,localname,qname|
        if gotlatlon && gotdate
          ele = '0' unless gotele
          if lat < 90 && lat > -90 && lon > -180 && lon < 180
            @actual_points += 1
            yield Hash['latitude' => lat,'longitude' => lon,'timestamp' => date,'altitude' => ele,'segment' => @tracksegs]
          end
        end
        gotlatlon = false
        gotele = false
        gotdate = false
      end
      parser.parse
    end
  end
end
