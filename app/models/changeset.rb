class Changeset < ActiveRecord::Base
  require 'xml/libxml'

  belongs_to :user

  has_many :changeset_tags, :foreign_key => 'id'

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
    print "noes "+ ex.to_s + "\n"
      cs = nil
    end

    return cs
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

    self.tags.each do |k,v|
      el2 = XML::Node.new('tag')
      el2['k'] = k.to_s
      el2['v'] = v.to_s
      el1 << el2
    end
    
    el1['created_at'] = self.created_at.xmlschema
    el1['open'] = self.open.to_s

    # FIXME FIXME FIXME: This does not include changes yet! There is 
    # currently no changeset_id column in the tables as far as I can tell,
    # so this is just a scaffold to build on, not a complete to_xml

    return el1
  end
end
