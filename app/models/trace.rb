# == Schema Information
#
# Table name: gpx_files
#
#  id          :bigint(8)        not null, primary key
#  user_id     :bigint(8)        not null
#  visible     :boolean          default(TRUE), not null
#  name        :string           default(""), not null
#  size        :bigint(8)
#  latitude    :float
#  longitude   :float
#  timestamp   :datetime         not null
#  description :string           default(""), not null
#  inserted    :boolean          not null
#  visibility  :enum             default("public"), not null
#
# Indexes
#
#  gpx_files_timestamp_idx           (timestamp)
#  gpx_files_user_id_idx             (user_id)
#  gpx_files_visible_visibility_idx  (visible,visibility)
#
# Foreign Keys
#
#  gpx_files_user_id_fkey  (user_id => users.id)
#

class Trace < ApplicationRecord
  require "open3"

  self.table_name = "gpx_files"

  belongs_to :user, :counter_cache => true
  has_many :tags, :class_name => "Tracetag", :foreign_key => "gpx_id", :dependent => :delete_all
  has_many :points, :class_name => "Tracepoint", :foreign_key => "gpx_id", :dependent => :delete_all

  scope :visible, -> { where(:visible => true) }
  scope :visible_to, ->(u) { visible.where("visibility IN ('public', 'identifiable') OR user_id = ?", u) }
  scope :visible_to_all, -> { where(:visibility => %w[public identifiable]) }
  scope :tagged, ->(t) { joins(:tags).where(:gpx_file_tags => { :tag => t }) }

  validates :user, :presence => true, :associated => true
  validates :name, :presence => true, :length => 1..255, :characters => true
  validates :description, :presence => { :on => :create }, :length => 1..255, :characters => true
  validates :timestamp, :presence => true
  validates :visibility, :inclusion => %w[private public trackable identifiable]

  after_destroy :remove_files

  def tagstring
    tags.collect(&:tag).join(", ")
  end

  def tagstring=(s)
    self.tags = if s.include? ","
                  s.split(/\s*,\s*/).grep_v(/^\s*$/).collect do |tag|
                    tt = Tracetag.new
                    tt.tag = tag
                    tt
                  end
                else
                  # do as before for backwards compatibility:
                  s.split.collect do |tag|
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
    "#{Settings.gpx_image_dir}/#{id}.gif"
  end

  def icon_picture_name
    "#{Settings.gpx_image_dir}/#{id}_icon.gif"
  end

  def trace_name
    "#{Settings.gpx_trace_dir}/#{id}.gpx"
  end

  def mime_type
    filetype = Open3.capture2("/usr/bin/file", "-Lbz", trace_name).first.chomp
    gzipped = filetype.include?("gzip compressed")
    bzipped = filetype.include?("bzip2 compressed")
    zipped = filetype.include?("Zip archive")
    tarred = filetype.include?("tar archive")

    if gzipped
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
  end

  def extension_name
    filetype = Open3.capture2("/usr/bin/file", "-Lbz", trace_name).first.chomp
    gzipped = filetype.include?("gzip compressed")
    bzipped = filetype.include?("bzip2 compressed")
    zipped = filetype.include?("Zip archive")
    tarred = filetype.include?("tar archive")

    if tarred && gzipped
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
  end

  def update_from_xml(xml, create: false)
    p = XML::Parser.string(xml, :options => XML::Parser::Options::NOERROR)
    doc = p.parse
    pt = doc.find_first("//osm/gpx_file")

    if pt
      update_from_xml_node(pt, :create => create)
    else
      raise OSM::APIBadXMLError.new("trace", xml, "XML doesn't contain an osm/gpx_file element.")
    end
  rescue LibXML::XML::Error, ArgumentError => e
    raise OSM::APIBadXMLError.new("trace", xml, e.message)
  end

  def update_from_xml_node(pt, create: false)
    raise OSM::APIBadXMLError.new("trace", pt, "visibility missing") if pt["visibility"].nil?

    self.visibility = pt["visibility"]

    unless create
      raise OSM::APIBadXMLError.new("trace", pt, "ID is required when updating.") if pt["id"].nil?

      id = pt["id"].to_i
      # .to_i will return 0 if there is no number that can be parsed.
      # We want to make sure that there is no id with zero anyway
      raise OSM::APIBadUserInput, "ID of trace cannot be zero when updating." if id.zero?
      raise OSM::APIBadUserInput, "The id in the url (#{self.id}) is not the same as provided in the xml (#{id})" unless self.id == id
    end

    # We don't care about the time, as it is explicitly set on create/update/delete
    # We don't care about the visibility as it is implicit based on the action
    # and set manually before the actual delete
    self.visible = true

    description = pt.find("description").first
    raise OSM::APIBadXMLError.new("trace", pt, "description missing") if description.nil?

    self.description = description.content

    self.tags = pt.find("tag").collect do |tag|
      Tracetag.new(:tag => tag.content)
    end
  end

  def xml_file
    filetype = Open3.capture2("/usr/bin/file", "-Lbz", trace_name).first.chomp
    gzipped = filetype.include?("gzip compressed")
    bzipped = filetype.include?("bzip2 compressed")
    zipped = filetype.include?("Zip archive")
    tarred = filetype.include?("tar archive")

    if gzipped || bzipped || zipped || tarred
      file = Tempfile.new("trace.#{id}")

      if tarred && gzipped
        system("tar", "-zxOf", trace_name, :out => file.path)
      elsif tarred && bzipped
        system("tar", "-jxOf", trace_name, :out => file.path)
      elsif tarred
        system("tar", "-xOf", trace_name, :out => file.path)
      elsif gzipped
        system("gunzip", "-c", trace_name, :out => file.path)
      elsif bzipped
        system("bunzip2", "-c", trace_name, :out => file.path)
      elsif zipped
        system("unzip", "-p", trace_name, "-x", "__MACOSX/*", :out => file.path, :err => "/dev/null")
      end

      file.unlink
    else
      file = File.open(trace_name)
    end

    file
  end

  def import
    logger.info("GPX Import importing #{name} (#{id}) from #{user.email}")

    gpx = GPX::File.new(trace_name)

    f_lat = 0
    f_lon = 0
    first = true

    # If there are any existing points for this trace then delete them
    Tracepoint.where(:gpx_id => id).delete_all

    gpx.points.each_slice(1_000) do |points|
      # Gather the trace points together for a bulk import
      tracepoints = []

      points.each do |point|
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
        tracepoints << tp
      end

      # Run the before_save and before_create callbacks, and then import them in bulk with activerecord-import
      tracepoints.each do |tp|
        tp.run_callbacks(:save) { false }
        tp.run_callbacks(:create) { false }
      end

      Tracepoint.import!(tracepoints)
    end

    if gpx.actual_points.positive?
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

  private

  def remove_files
    FileUtils.rm_f(trace_name)
    FileUtils.rm_f(icon_picture_name)
    FileUtils.rm_f(large_picture_name)
  end
end
