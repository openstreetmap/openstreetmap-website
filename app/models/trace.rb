class Trace < ActiveRecord::Base
  set_table_name 'gpx_files'

  validates_presence_of :user_id, :name, :public, :description, :timestamp
#  validates_numericality_of :latitude, :longitude
  validates_inclusion_of :inserted, :in => [ true, false]
  
  belongs_to :user
  has_many :tags, :class_name => 'Tracetag', :foreign_key => 'gpx_id', :dependent => :destroy

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
    "/tmp/#{id}.gif"
  end

  # FIXME change to permanent filestore area
  def icon_picture_name
    "/tmp/#{id}_icon.gif"
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
end
