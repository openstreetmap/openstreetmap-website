class Changeset < ActiveRecord::Base
  require 'xml/libxml'

  belongs_to :user

  has_many :changeset_tags, :foreign_key => 'id'
  
  has_many :nodes
  has_many :ways
  has_many :relations
  has_many :old_nodes
  has_many :old_ways
  has_many :old_relations
  
  validates_presence_of :user_id, :created_at
  validates_inclusion_of :open, :in => [ true, false ]
  
  # over-expansion factor to use when updating the bounding box
  EXPAND = 0.1

  # Use a method like this, so that we can easily change how we
  # determine whether a changeset is open, without breaking code in at 
  # least 6 controllers
  def is_open?
    return open
  end

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.new
      p.string = xml
      doc = p.parse

      cs = Changeset.new

      doc.find('//osm/changeset').each do |pt|
        if create
          cs.created_at = Time.now
        end

        pt.find('tag').each do |tag|
          cs.add_tag_keyval(tag['k'], tag['v'])
        end
      end
    rescue Exception => ex
      cs = nil
    end

    return cs
  end

  ##
  # returns the bounding box of the changeset. it is possible that some
  # or all of the values will be nil, indicating that they are undefined.
  def bbox
    @bbox ||= [ min_lon, min_lat, max_lon, max_lat ]
  end

  ##
  # expand the bounding box to include the given bounding box. also, 
  # expand a little bit more in the direction of the expansion, so that
  # further expansions may be unnecessary. this is an optimisation 
  # suggested on the wiki page by kleptog.
  def update_bbox!(array)
    # ensure that bbox is cached and has no nils in it. if there are any
    # nils, just use the bounding box update to write over them.
    @bbox = bbox.zip(array).collect { |a, b| a.nil? ? b : a }

    # FIXME - this looks nasty and violates DRY... is there any prettier 
    # way to do this? 
    @bbox[0] = array[0] + EXPAND * (@bbox[0] - @bbox[2]) if array[0] < @bbox[0]
    @bbox[1] = array[1] + EXPAND * (@bbox[1] - @bbox[3]) if array[1] < @bbox[1]
    @bbox[2] = array[2] + EXPAND * (@bbox[2] - @bbox[0]) if array[2] > @bbox[2]
    @bbox[3] = array[3] + EXPAND * (@bbox[3] - @bbox[1]) if array[3] > @bbox[3]

    # update active record. rails 2.1's dirty handling should take care of
    # whether this object needs saving or not.
    self.min_lon, self.min_lat, self.max_lon, self.max_lat = @bbox
  end

  def tags_as_hash
    return tags
  end

  def tags
    unless @tags
      @tags = {}
      self.changeset_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  def tags=(t)
    @tags = t
  end

  def add_tag_keyval(k, v)
    @tags = Hash.new unless @tags
    @tags[k] = v
  end

  def save_with_tags!
    t = Time.now

    Changeset.transaction do
      # fixme update modified_at time?
      # FIXME there is no modified_at time, should it be added
      self.save!
    end

    ChangesetTag.transaction do
      tags = self.tags
      ChangesetTag.delete_all(['id = ?', self.id])

      tags.each do |k,v|
        tag = ChangesetTag.new
        tag.k = k
        tag.v = v
        tag.id = self.id
        tag.save!
      end
    end
  end
  
  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end
  
  def to_xml_node(user_display_name_cache = nil)
    el1 = XML::Node.new 'changeset'
    el1['id'] = self.id.to_s

    user_display_name_cache = {} if user_display_name_cache.nil?

    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?
    el1['uid'] = self.user_id.to_s if self.user.data_public?

    self.tags.each do |k,v|
      el2 = XML::Node.new('tag')
      el2['k'] = k.to_s
      el2['v'] = v.to_s
      el1 << el2
    end
    
    el1['created_at'] = self.created_at.xmlschema
    el1['open'] = self.open.to_s

    el1['min_lon'] = (bbox[0].to_f / GeoRecord::SCALE).to_s unless bbox[0].nil?
    el1['min_lat'] = (bbox[1].to_f / GeoRecord::SCALE).to_s unless bbox[1].nil?
    el1['max_lon'] = (bbox[2].to_f / GeoRecord::SCALE).to_s unless bbox[2].nil?
    el1['max_lat'] = (bbox[3].to_f / GeoRecord::SCALE).to_s unless bbox[3].nil?
    
    # NOTE: changesets don't include the XML of the changes within them,
    # they are just structures for tagging. to get the osmChange of a
    # changeset, see the download method of the controller.

    return el1
  end
end
