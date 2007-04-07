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
  require 'xml/libxml'
  require 'RMagick'

  class Mercator
    include Math

    def initialize(lat, lon, degrees_per_pixel, width, height)
      #init me with your centre lat/lon, the number of degrees per pixel and the size of your image
      @clat = lat
      @clon = lon
      @degrees_per_pixel = degrees_per_pixel
      @width = width
      @height = height
      @dlon = width / 2 * degrees_per_pixel
      @dlat = height / 2 * degrees_per_pixel  * cos(@clat * PI / 180)

      @tx = xsheet(@clon - @dlon)
      @ty = ysheet(@clat - @dlat)

      @bx = xsheet(@clon + @dlon)
      @by = ysheet(@clat + @dlat)

    end

    #the following two functions will give you the x/y on the entire sheet

    def kilometerinpixels
      return 40008.0  / 360.0 * @degrees_per_pixel
    end

    def ysheet(lat)
      log(tan(PI / 4 +  (lat  * PI / 180 / 2)))
    end

    def xsheet(lon)
      lon
    end

    #and these two will give you the right points on your image. all the constants can be reduced to speed things up. FIXME

    def y(lat)
      return @height - ((ysheet(lat) - @ty) / (@by - @ty) * @height)
    end

    def x(lon)
      return  ((xsheet(lon) - @tx) / (@bx - @tx) * @width)
    end
  end


  class GPXImporter
    # FIXME swap REXML for libXML
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

    def get_picture(min_lat, min_lon, max_lat, max_lon, num_points)
      frames = 10
      width = 250
      height = 250
      rat= Math.cos( ((max_lat + min_lat)/2.0) /  180.0 * 3.141592)
      proj = OSM::Mercator.new((min_lat + max_lat) / 2, (max_lon + min_lon) / 2, (max_lat - min_lat) / width / rat, width, height)

      images = []

      frames.times do
        gc =  Magick::Draw.new
        gc.stroke_linejoin('miter')
        gc.stroke('#FFFFFF')
        gc.fill('#FFFFFF')
        gc.rectangle(0,0,width,height)
        gc.stroke_width(1)
        images << gc
      end

      oldpx = 0.0
      oldpy = 0.0

      first = true

      m = 0
      mm = 0
      points do |p|
        px = proj.x(p['longitude'])
        py = proj.y(p['latitude'])
        frames.times do |n|
          images[n].stroke_width(1)
          images[n].stroke('#BBBBBB')
          images[n].fill('#BBBBBB')
          images[n].line(px, py, oldpx, oldpy ) unless first
        end
        images[mm].stroke_width(3)
        images[mm].stroke('#000000')
        images[mm].fill('#000000')
        images[mm].line(px, py, oldpx, oldpy ) unless first

        m +=1
        if m > num_points.to_f / frames.to_f * (mm+1)
          mm += 1
        end
        first = false
        oldpy = py
        oldpx = px
      end

      il = Magick::ImageList.new

      frames.times do |n|
        canvas = Magick::Image.new(width, height) {
          self.background_color = 'white'
        }
        begin
          images[n].draw(canvas)
        rescue ArgumentError
        end
        canvas.format = 'GIF'
        il << canvas
      end

      il.delay = 50
      il.format = 'GIF'
      return il.to_blob
    end

    def get_icon(min_lat, min_lon, max_lat, max_lon)
      width = 50
      height = 50
      rat= Math.cos( ((max_lat + min_lat)/2.0) /  180.0 * 3.141592)
      proj = OSM::Mercator.new((min_lat + max_lat) / 2, (max_lon + min_lon) / 2, (max_lat - min_lat) / width / rat, width, height)

      images = []

      gc =  Magick::Draw.new
      gc.stroke_linejoin('miter')

      oldpx = 0.0
      oldpy = 0.0

      first = true

      gc.stroke_width(1)
      gc.stroke('#000000')
      gc.fill('#000000')

      points do |p|
        px = proj.x(p['longitude'])
        py = proj.y(p['latitude'])
        gc.line(px, py, oldpx, oldpy ) unless first
        first = false
        oldpy = py
        oldpx = px
      end

      canvas = Magick::Image.new(width, height) {
        self.background_color = 'white'
      }
      begin
        gc.draw(canvas)
      rescue ArgumentError
      end
      canvas.format = 'GIF'
      return canvas.to_blob
    end

  end

  class GeoRSS
    def initialize(description='OpenStreetMap GPS Traces')
      @doc = XML::Document.new
      @doc.encoding = 'UTF-8' 
      
      rss = XML::Node.new 'rss'
      @doc.root = rss
      rss['version'] = "2.0"
      rss['xmlns:geo'] = "http://www.w3.org/2003/01/geo/wgs84_pos#"
      @channel = XML::Node.new 'channel'
      rss << @channel
      title = XML::Node.new 'title'
      title <<  'OpenStreetMap GPS Traces'
      @channel << title
      description_el = XML::Node.new 'description'
      @channel << description_el

      description_el << description
      link = XML::Node.new 'link'
      link << 'http://www.openstreetmap.org/traces/'
      @channel << link
      image = XML::Node.new 'image'
      @channel << image
      url = XML::Node.new 'url'
      url << 'http://www.openstreetmap.org/feeds/mag_map-rss2.0.png'
      image << url
      title = XML::Node.new 'title'
      title << "OpenStreetMap"
      image << title
      width = XML::Node.new 'width'
      width << '100'
      image << width
      height = XML::Node.new 'height'
      height << '100'
      image << height
      link = XML::Node.new 'link'
      link << 'http://www.openstreetmap.org/traces/'
      image << link
    end

    def add(latitude=0, longitude=0, title_text='dummy title', url='http://www.example.com/', description_text='dummy description', timestamp=Time.now)
      item = XML::Node.new 'item'

      title = XML::Node.new 'title'
      item << title
      title << title_text
      link = XML::Node.new 'link'
      link << url
      item << link

      description = XML::Node.new 'description'
      description << description_text
      item << description

      pubDate = XML::Node.new 'pubDate'
      pubDate << timestamp.xmlschema
      item << pubDate

      lat_el = XML::Node.new 'geo:lat'
      lat_el << latitude.to_s
      item << lat_el

      lon_el = XML::Node.new 'geo:lon'
      lon_el << longitude.to_s
      item << lon_el

      @channel << item
    end

    def to_s
      return @doc.to_s
    end
  end

  class API
    def get_xml_doc
      doc = XML::Document.new
      doc.encoding = 'UTF-8' 
      root = XML::Node.new 'osm'
      root['version'] = API_VERSION
      root['generator'] = 'OpenStreetMap server'
      doc.root = root
      return doc
    end
  end
end
