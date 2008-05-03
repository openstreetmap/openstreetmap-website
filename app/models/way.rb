class Way < ActiveRecord::Base
  require 'xml/libxml'

  belongs_to :user

  has_many :nodes, :through => :way_nodes, :order => 'sequence_id'
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
    #If waytag had a multipart key that was real, you could do this:
    #way = Way.find(id, :include => [:way_tags, {:way_nodes => :node}])
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
      self.version += 1
      self.timestamp = t
      self.save!

      tags = self.tags
      WayTag.delete_all(['id = ?', self.id])
      tags.each do |k,v|
        tag = WayTag.new
        tag.k = k
        tag.v = v
        tag.id = self.id
        tag.save!
      end

      nds = self.nds
      WayNode.delete_all(['id = ?', self.id])
      sequence = 1
      nds.each do |n|
        nd = WayNode.new
        nd.id = [self.id, sequence]
        nd.node_id = n
        nd.save!
        sequence += 1
      end

      old_way = OldWay.from_way(self)
      old_way.timestamp = t
      old_way.save_with_dependencies!
    end
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

  # Delete the way and it's relations, but don't really delete it - set its visibility to false and update the history etc to maintain wiki-like functionality.
  def delete_with_relations_and_history(user)
    if self.visible
	  # FIXME
	  # this should actually delete the relations,
	  # not just throw a PreconditionFailed if it's a member of a relation!!
      if RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id",
                             :conditions => [ "visible = 1 AND member_type='way' and member_id=?", self.id])
        raise OSM::APIPreconditionFailedError
      # end FIXME
      else
        self.user_id = user.id
        self.tags = []
        self.nds = []
        self.visible = false
        self.save_with_history!
      end
    else
      raise OSM::APIAlreadyDeletedError
    end
  end

  # delete a way and it's nodes that aren't part of other ways, with history
  def delete_with_relations_and_nodes_and_history(user)
    
    node_ids = self.nodes.collect {|node| node.id }
    node_ids_not_to_delete = []
    way_nodes = WayNode.find(:all, :conditions => "node_id in (#{node_ids.join(',')}) and id != #{self.id}")
    
    node_ids_not_to_delete = way_nodes.collect {|way_node| way_node.node_id}

    node_ids_to_delete = node_ids - node_ids_not_to_delete

    # delete the nodes not used by other ways
    node_ids_to_delete.each do |node_id|
      n = Node.find(node_id)
      n.user_id = user.id
      n.visible = false
      n.save_with_history!
    end
    
    self.user_id = user.id

    self.delete_with_relations_and_history(user)

  end
end
