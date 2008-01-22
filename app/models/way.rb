class Way < ActiveRecord::Base
  require 'xml/libxml'

  belongs_to :user

  has_many :way_nodes, :foreign_key => 'id', :order => 'sequence_id'
  has_many :way_tags, :foreign_key => 'id'

  has_many :old_ways, :foreign_key => 'id', :order => 'version'

  set_table_name 'current_ways'

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.new
      p.string = xml
      doc = p.parse

      way = Way.new

      doc.find('//osm/way').each do |pt|
        if !create and pt['id'] != '0'
          way.id = pt['id'].to_i
        end

        if create
          way.timestamp = Time.now
          way.visible = true
        else
          if pt['timestamp']
            way.timestamp = Time.parse(pt['timestamp'])
          end
        end

        pt.find('tag').each do |tag|
          way.add_tag_keyval(tag['k'], tag['v'])
        end

        pt.find('nd').each do |nd|
          way.add_nd_num(nd['ref'])
        end
      end
    rescue
      way = nil
    end

    return way
  end

  # Find a way given it's ID, and in a single SQL call also grab its nodes
  #
  # You can't pull in all the tags too unless we put a sequence_id on the way_tags table and have a multipart key
  def self.find_eager(id)
    way = Way.find(id, :include => {:way_nodes => :node})
  end

  # Find a way given it's ID, and in a single SQL call also grab its nodes and tags
  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node(visible_nodes = nil, user_display_name_cache = nil)
    el1 = XML::Node.new 'way'
    el1['id'] = self.id.to_s
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema

    user_display_name_cache = {} if user_display_name_cache.nil?

    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?

    # make sure nodes are output in sequence_id order
    ordered_nodes = []
    self.way_nodes.each do |nd|
      if visible_nodes
        # if there is a list of visible nodes then use that to weed out deleted nodes
        if visible_nodes[nd.node_id]
          ordered_nodes[nd.sequence_id] = nd.node_id.to_s
        end
      else
        # otherwise, manually go to the db to check things
        if nd.node.visible? and nd.node.visible?
          ordered_nodes[nd.sequence_id] = nd.node_id.to_s
        end
      end
    end

    ordered_nodes.each do |nd_id|
      if nd_id and nd_id != '0'
        e = XML::Node.new 'nd'
        e['ref'] = nd_id
        el1 << e
      end
    end

    self.way_tags.each do |tag|
      e = XML::Node.new 'tag'
      e['k'] = tag.k
      e['v'] = tag.v
      el1 << e
    end
    return el1
  end 

  def nds
    unless @nds
      @nds = Array.new
      self.way_nodes.each do |nd|
        @nds += [nd.node_id]
      end
    end
    @nds
  end

  def tags
    unless @tags
      @tags = {}
      self.way_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  def nds=(s)
    @nds = s
  end

  def tags=(t)
    @tags = t
  end

  def add_nd_num(n)
    @nds = Array.new unless @nds
    @nds << n.to_i
  end

  def add_tag_keyval(k, v)
    @tags = Hash.new unless @tags
    @tags[k] = v
  end

  def save_with_history!
    t = Time.now

    Way.transaction do
      self.timestamp = t
      self.save!
    end

    WayTag.transaction do
      tags = self.tags

      WayTag.delete_all(['id = ?', self.id])

      tags.each do |k,v|
        tag = WayTag.new
        tag.k = k
        tag.v = v
        tag.id = self.id
        tag.save!
      end
    end

    WayNode.transaction do
      nds = self.nds

      WayNode.delete_all(['id = ?', self.id])

      i = 1
      nds.each do |n|
        nd = WayNode.new
        nd.id = self.id
        nd.node_id = n
        nd.sequence_id = i
        nd.save!
        i += 1
      end
    end

    old_way = OldWay.from_way(self)
    old_way.timestamp = t
    old_way.save_with_dependencies!
  end

  def preconditions_ok?
    return false if self.nds.empty?
    self.nds.each do |n|
      node = Node.find(:first, :conditions => ["id = ?", n])
      unless node and node.visible
        return false
      end
    end
    return true
  end

end
