class Trace < ActiveRecord::Base
  set_table_name 'gpx_files'

  validates_presence_of :user_id, :name, :timestamp
  validates_presence_of :description, :on => :create
#  validates_numericality_of :latitude, :longitude
  validates_inclusion_of :public, :inserted, :in => [ true, false]
  
  belongs_to :user
  has_many :tags, :class_name => 'Tracetag', :foreign_key => 'gpx_id', :dependent => :delete_all
  has_many :points, :class_name => 'Tracepoint', :foreign_key => 'gpx_id', :dependent => :delete_all

  def destroy
    super
    FileUtils.rm_f(trace_name)
    FileUtils.rm_f(icon_picture_name)
    FileUtils.rm_f(large_picture_name)
  end

  def tagstring
    return tags.collect {|tt| tt.tag}.join(" ")
  end

  def tagstring=(s)
    self.tags = s.split().collect {|tag|
      tt = Tracetag.new
      tt.tag = tag
      tt
    }
  end
  
  def large_picture= (data)
    f = File.new(large_picture_name, "wb")
    f.syswrite(data)
    f.close
  end
  
  def icon_picture= (data)
    f = File.new(icon_picture_name, "wb")
    f.syswrite(data)
    f.close
  end

  def large_picture
    f = File.new(large_picture_name, "rb")
    logger.info "large picture file: '#{f.path}', bytes: #{File.size(f.path)}"
    data = f.sysread(File.size(f.path))
    logger.info "have read data, bytes: '#{data.length}'"
    f.close
    data
  end
  
  def icon_picture
    f = File.new(icon_picture_name, "rb")
    logger.info "icon picture file: '#{f.path}'"
    data = f.sysread(File.size(f.path))
    f.close
    data
  end
  
  # FIXME change to permanent filestore area
  def large_picture_name
    "/home/osm/icons/#{id}.gif"
  end

  # FIXME change to permanent filestore area
  def icon_picture_name
    "/home/osm/icons/#{id}_icon.gif"
  end

  def trace_name
    "/home/osm/gpx/#{id}.gpx"
  end

  def mime_type
    filetype = `/usr/bin/file -bz #{trace_name}`.chomp
    gzipped = filetype =~ /gzip compressed/
    bzipped = filetype =~ /bzip2 compressed/
    zipped = filetype =~ /Zip archive/

    if gzipped then
      mimetype = "application/x-gzip"
    elsif bzipped then
      mimetype = "application/x-bzip2"
    elsif zipped
      mimetype = "application/x-zip"
    else
      mimetype = "text/xml"
    end

    return mimetype
  end

  def extension_name
    filetype = `/usr/bin/file -bz #{trace_name}`.chomp
    gzipped = filetype =~ /gzip compressed/
    bzipped = filetype =~ /bzip2 compressed/
    zipped = filetype =~ /Zip archive/
    tarred = filetype =~ /tar archive/

    if tarred and gzipped then
      extension = ".tar.gz"
    elsif tarred and bzipped then
      extension = ".tar.bz2"
    elsif tarred
      extension = ".tar"
    elsif gzipped
      extension = ".gpx.gz"
    elsif bzipped
      extension = ".gpx.bz2"
    elsif zipped
      extension = ".zip"
    else
      extension = ".gpx"
    end

    return extension
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node
    el1 = XML::Node.new 'gpx_file'
    el1['id'] = self.id.to_s
    el1['name'] = self.name.to_s
    el1['lat'] = self.latitude.to_s
    el1['lon'] = self.longitude.to_s
    el1['user'] = self.user.display_name
    el1['public'] = self.public.to_s
    el1['pending'] = (!self.inserted).to_s
    el1['timestamp'] = self.timestamp.xmlschema
    return el1
  end

  def import
    begin
      logger.info("GPX Import importing #{name} (#{id}) from #{user.email}")

      # TODO *nix specific, could do to work on windows... would be functionally inferior though - check for '.gz'
      filetype = `/usr/bin/file -bz #{trace_name}`.chomp
      gzipped = filetype =~ /gzip compressed/
      bzipped = filetype =~ /bzip2 compressed/
      zipped = filetype =~ /Zip archive/
      tarred = filetype =~ /tar archive/

      if tarred and gzipped then
        filename = tempfile = "/tmp/#{rand}"
        system("tar -zxOf #{trace_name} > #{filename}")
      elsif tarred and bzipped then
        filename = tempfile = "/tmp/#{rand}"
        system("tar -jxOf #{trace_name} > #{filename}")
      elsif tarred
        filename = tempfile = "/tmp/#{rand}"
        system("tar -xOf #{trace_name} > #{filename}")
      elsif gzipped
        filename = tempfile = "/tmp/#{rand}"
        system("gunzip -c #{trace_name} > #{filename}")
      elsif bzipped
        filename = tempfile = "/tmp/#{rand}"
        system("bunzip2 -c #{trace_name} > #{filename}")
      elsif zipped
        filename = tempfile = "/tmp/#{rand}"
        system("unzip -p #{trace_name} > #{filename}")
      else
        filename = trace_name
      end

      gpx = OSM::GPXImporter.new(filename)

      f_lat = 0
      f_lon = 0
      first = true

      # If there are any existing points for this trace then delete
      # them - we check for existing points first to avoid locking
      # the table in the common case where there aren't any.
      if Tracepoint.exists?(['gpx_id = ?', self.id])
        Tracepoint.delete_all(['gpx_id = ?', self.id])
      end

      gpx.points do |point|
        if first
          f_lat = point['latitude']
          f_lon = point['longitude']
        end

        tp = Tracepoint.new
        tp.lat = point['latitude'].to_f
        tp.lng = point['longitude'].to_f
        tp.altitude = point['altitude'].to_f
        tp.timestamp = point['timestamp']
        tp.gpx_id = id
        tp.trackid = point['segment'].to_i
        tp.save!
      end

      if gpx.actual_points > 0
        max_lat = Tracepoint.maximum('latitude', :conditions => ['gpx_id = ?', id])
        min_lat = Tracepoint.minimum('latitude', :conditions => ['gpx_id = ?', id])
        max_lon = Tracepoint.maximum('longitude', :conditions => ['gpx_id = ?', id])
        min_lon = Tracepoint.minimum('longitude', :conditions => ['gpx_id = ?', id])

        max_lat = max_lat.to_f / 1000000
        min_lat = min_lat.to_f / 1000000
        max_lon = max_lon.to_f / 1000000
        min_lon = min_lon.to_f / 1000000

        self.latitude = f_lat
        self.longitude = f_lon
        self.large_picture = gpx.get_picture(min_lat, min_lon, max_lat, max_lon, gpx.actual_points)
        self.icon_picture = gpx.get_icon(min_lat, min_lon, max_lat, max_lon)
        self.size = gpx.actual_points
        self.inserted = true
        self.save!
      end

      logger.info "done trace #{id}"

      return gpx
    ensure
      FileUtils.rm_f(tempfile) if tempfile
    end
  end
end
