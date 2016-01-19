class Trace < ActiveRecord::Base
  self.table_name = "gpx_files"

  belongs_to :user, :counter_cache => true
  has_many :tags, :class_name => "Tracetag", :foreign_key => "gpx_id", :dependent => :delete_all
  has_many :points, :class_name => "Tracepoint", :foreign_key => "gpx_id", :dependent => :delete_all

  scope :visible, -> { where(:visible => true) }
  scope :visible_to, ->(u) { visible.where("visibility IN ('public', 'identifiable') OR user_id = ?", u) }
  scope :visible_to_all, -> { where(:visibility => %w(public identifiable)) }
  scope :tagged, ->(t) { joins(:tags).where(:gpx_file_tags => { :tag => t }) }

  validates :user, :presence => true, :associated => true
  validates :name, :presence => true, :length => 1..255
  validates :description, :presence => { :on => :create }, :length => 1..255
  validates :timestamp, :presence => true
  validates :visibility, :inclusion => %w(private public trackable identifiable)

  def destroy
    super
    FileUtils.rm_f(trace_name)
    FileUtils.rm_f(icon_picture_name)
    FileUtils.rm_f(large_picture_name)
  end

  def tagstring
    tags.collect(&:tag).join(", ")
  end

  def tagstring=(s)
    self.tags = if s.include? ","
                  s.split(/\s*,\s*/).select { |tag| tag !~ /^\s*$/ }.collect do|tag|
                    tt = Tracetag.new
                    tt.tag = tag
                    tt
                  end
                else
                  # do as before for backwards compatibility:
                  s.split.collect do|tag|
                    tt = Tracetag.new
                    tt.tag = tag
                    tt
                  end
                end
  end

  def public?
    visibility == "public" || visibility == "identifiable"
  end

  def trackable?
    visibility == "trackable" || visibility == "identifiable"
  end

  def identifiable?
    visibility == "identifiable"
  end

  def large_picture=(data)
    f = File.new(large_picture_name, "wb")
    f.syswrite(data)
    f.close
  end

  def icon_picture=(data)
    f = File.new(icon_picture_name, "wb")
    f.syswrite(data)
    f.close
  end

  def large_picture
    f = File.new(large_picture_name, "rb")
    data = f.sysread(File.size(f.path))
    f.close
    data
  end

  def icon_picture
    f = File.new(icon_picture_name, "rb")
    data = f.sysread(File.size(f.path))
    f.close
    data
  end

  def large_picture_name
    "#{GPX_IMAGE_DIR}/#{id}.gif"
  end

  def icon_picture_name
    "#{GPX_IMAGE_DIR}/#{id}_icon.gif"
  end

  def trace_name
    "#{GPX_TRACE_DIR}/#{id}.gpx"
  end

  def mime_type
    filetype = `/usr/bin/file -bz #{trace_name}`.chomp
    gzipped = filetype =~ /gzip compressed/
    bzipped = filetype =~ /bzip2 compressed/
    zipped = filetype =~ /Zip archive/
    tarred = filetype =~ /tar archive/

    mimetype = if gzipped
                 "application/x-gzip"
               elsif bzipped
                 "application/x-bzip2"
               elsif zipped
                 "application/x-zip"
               elsif tarred
                 "application/x-tar"
               else
                 "application/gpx+xml"
               end

    mimetype
  end

  def extension_name
    filetype = `/usr/bin/file -bz #{trace_name}`.chomp
    gzipped = filetype =~ /gzip compressed/
    bzipped = filetype =~ /bzip2 compressed/
    zipped = filetype =~ /Zip archive/
    tarred = filetype =~ /tar archive/

    extension = if tarred && gzipped
                  ".tar.gz"
                elsif tarred && bzipped
                  ".tar.bz2"
                elsif tarred
                  ".tar"
                elsif gzipped
                  ".gpx.gz"
                elsif bzipped
                  ".gpx.bz2"
                elsif zipped
                  ".zip"
                else
                  ".gpx"
                end

    extension
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node
    doc
  end

  def to_xml_node
    el1 = XML::Node.new "gpx_file"
    el1["id"] = id.to_s
    el1["name"] = name.to_s
    el1["lat"] = latitude.to_s if inserted
    el1["lon"] = longitude.to_s if inserted
    el1["user"] = user.display_name
    el1["visibility"] = visibility
    el1["pending"] = inserted ? "false" : "true"
    el1["timestamp"] = timestamp.xmlschema

    el2 = XML::Node.new "description"
    el2 << description
    el1 << el2

    tags.each do |tag|
      el2 = XML::Node.new("tag")
      el2 << tag.tag
      el1 << el2
    end

    el1
  end

  # Read in xml as text and return it's Node object representation
  def self.from_xml(xml, create = false)
    p = XML::Parser.string(xml)
    doc = p.parse

    doc.find("//osm/gpx_file").each do |pt|
      return Trace.from_xml_node(pt, create)
    end

    fail OSM::APIBadXMLError.new("trace", xml, "XML doesn't contain an osm/gpx_file element.")
  rescue LibXML::XML::Error, ArgumentError => ex
    raise OSM::APIBadXMLError.new("trace", xml, ex.message)
  end

  def self.from_xml_node(pt, create = false)
    trace = Trace.new

    fail OSM::APIBadXMLError.new("trace", pt, "visibility missing") if pt["visibility"].nil?
    trace.visibility = pt["visibility"]

    unless create
      fail OSM::APIBadXMLError.new("trace", pt, "ID is required when updating.") if pt["id"].nil?
      trace.id = pt["id"].to_i
      # .to_i will return 0 if there is no number that can be parsed.
      # We want to make sure that there is no id with zero anyway
      fail OSM::APIBadUserInput.new("ID of trace cannot be zero when updating.") if trace.id == 0
    end

    # We don't care about the time, as it is explicitly set on create/update/delete
    # We don't care about the visibility as it is implicit based on the action
    # and set manually before the actual delete
    trace.visible = true

    description = pt.find("description").first
    fail OSM::APIBadXMLError.new("trace", pt, "description missing") if description.nil?
    trace.description = description.content

    pt.find("tag").each do |tag|
      trace.tags.build(:tag => tag.content)
    end

    trace
  end

  def xml_file
    # TODO: *nix specific, could do to work on windows... would be functionally inferior though - check for '.gz'
    filetype = `/usr/bin/file -bz #{trace_name}`.chomp
    gzipped = filetype =~ /gzip compressed/
    bzipped = filetype =~ /bzip2 compressed/
    zipped = filetype =~ /Zip archive/
    tarred = filetype =~ /tar archive/

    if gzipped || bzipped || zipped || tarred
      tmpfile = Tempfile.new("trace.#{id}")

      if tarred && gzipped
        system("tar -zxOf #{trace_name} > #{tmpfile.path}")
      elsif tarred && bzipped
        system("tar -jxOf #{trace_name} > #{tmpfile.path}")
      elsif tarred
        system("tar -xOf #{trace_name} > #{tmpfile.path}")
      elsif gzipped
        system("gunzip -c #{trace_name} > #{tmpfile.path}")
      elsif bzipped
        system("bunzip2 -c #{trace_name} > #{tmpfile.path}")
      elsif zipped
        system("unzip -p #{trace_name} -x '__MACOSX/*' > #{tmpfile.path} 2> /dev/null")
      end

      tmpfile.unlink

      file = tmpfile.file
    else
      file = File.open(trace_name)
    end

    file
  end

  def import
    logger.info("GPX Import importing #{name} (#{id}) from #{user.email}")

    gpx = GPX::File.new(xml_file)

    f_lat = 0
    f_lon = 0
    first = true

    # If there are any existing points for this trace then delete them
    Tracepoint.delete_all(:gpx_id => id)

    gpx.points do |point|
      if first
        f_lat = point.latitude
        f_lon = point.longitude
        first = false
      end

      tp = Tracepoint.new
      tp.lat = point.latitude
      tp.lon = point.longitude
      tp.altitude = point.altitude
      tp.timestamp = point.timestamp
      tp.gpx_id = id
      tp.trackid = point.segment
      tp.save!
    end

    if gpx.actual_points > 0
      max_lat = Tracepoint.where(:gpx_id => id).maximum(:latitude)
      min_lat = Tracepoint.where(:gpx_id => id).minimum(:latitude)
      max_lon = Tracepoint.where(:gpx_id => id).maximum(:longitude)
      min_lon = Tracepoint.where(:gpx_id => id).minimum(:longitude)

      max_lat = max_lat.to_f / 10000000
      min_lat = min_lat.to_f / 10000000
      max_lon = max_lon.to_f / 10000000
      min_lon = min_lon.to_f / 10000000

      self.latitude = f_lat
      self.longitude = f_lon
      self.large_picture = gpx.picture(min_lat, min_lon, max_lat, max_lon, gpx.actual_points)
      self.icon_picture = gpx.icon(min_lat, min_lon, max_lat, max_lon)
      self.size = gpx.actual_points
      self.inserted = true
      save!
    end

    logger.info "done trace #{id}"

    gpx
  end
end
