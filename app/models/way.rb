# == Schema Information
#
# Table name: current_ways
#
#  id           :integer          not null, primary key
#  changeset_id :integer          not null
#  timestamp    :datetime         not null
#  visible      :boolean          not null
#  version      :integer          not null
#
# Indexes
#
#  current_ways_timestamp_idx  (timestamp)
#
# Foreign Keys
#
#  current_ways_changeset_id_fkey  (changeset_id => changesets.id)
#

class Way < ActiveRecord::Base
  require "xml/libxml"

  include ConsistencyValidations
  include NotRedactable
  include ObjectMetadata

  self.table_name = "current_ways"

  belongs_to :changeset

  has_many :old_ways, -> { order(:version) }

  has_many :way_nodes, -> { order(:sequence_id) }
  has_many :nodes, :through => :way_nodes

  has_many :way_tags

  has_many :containing_relation_members, :class_name => "RelationMember", :as => :member
  has_many :containing_relations, :class_name => "Relation", :through => :containing_relation_members, :source => :relation

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :version, :presence => true,
                      :numericality => { :integer_only => true }
  validates :changeset_id, :presence => true,
                           :numericality => { :integer_only => true }
  validates :timestamp, :presence => true
  validates :changeset, :associated => true
  validates :visible, :inclusion => [true, false]

  scope :visible, -> { where(:visible => true) }
  scope :invisible, -> { where(:visible => false) }

  # Read in xml as text and return it's Way object representation
  def self.from_xml(xml, create = false)
    p = XML::Parser.string(xml, :options => XML::Parser::Options::NOERROR)
    doc = p.parse

    doc.find("//osm/way").each do |pt|
      return Way.from_xml_node(pt, create)
    end
    raise OSM::APIBadXMLError.new("node", xml, "XML doesn't contain an osm/way element.")
  rescue LibXML::XML::Error, ArgumentError => ex
    raise OSM::APIBadXMLError.new("way", xml, ex.message)
  end

  def self.from_xml_node(pt, create = false)
    way = Way.new

    raise OSM::APIBadXMLError.new("way", pt, "Version is required when updating") unless create || !pt["version"].nil?
    way.version = pt["version"]
    raise OSM::APIBadXMLError.new("way", pt, "Changeset id is missing") if pt["changeset"].nil?
    way.changeset_id = pt["changeset"]

    unless create
      raise OSM::APIBadXMLError.new("way", pt, "ID is required when updating") if pt["id"].nil?
      way.id = pt["id"].to_i
      # .to_i will return 0 if there is no number that can be parsed.
      # We want to make sure that there is no id with zero anyway
      raise OSM::APIBadUserInput, "ID of way cannot be zero when updating." if way.id.zero?
    end

    # We don't care about the timestamp nor the visibility as these are either
    # set explicitly or implicit in the action. The visibility is set to true,
    # and manually set to false before the actual delete.
    way.visible = true

    # Start with no tags
    way.tags = {}

    # Add in any tags from the XML
    pt.find("tag").each do |tag|
      raise OSM::APIBadXMLError.new("way", pt, "tag is missing key") if tag["k"].nil?
      raise OSM::APIBadXMLError.new("way", pt, "tag is missing value") if tag["v"].nil?
      way.add_tag_keyval(tag["k"], tag["v"])
    end

    pt.find("nd").each do |nd|
      way.add_nd_num(nd["ref"])
    end

    way
  end

  # Find a way given it's ID, and in a single SQL call also grab its nodes and tags
  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node
    doc
  end

  def to_xml_node(visible_nodes = nil, changeset_cache = {}, user_display_name_cache = {})
    el = XML::Node.new "way"
    el["id"] = id.to_s

    add_metadata_to_xml_node(el, self, changeset_cache, user_display_name_cache)

    # make sure nodes are output in sequence_id order
    ordered_nodes = []
    way_nodes.each do |nd|
      if visible_nodes
        # if there is a list of visible nodes then use that to weed out deleted nodes
        ordered_nodes[nd.sequence_id] = nd.node_id.to_s if visible_nodes[nd.node_id]
      else
        # otherwise, manually go to the db to check things
        ordered_nodes[nd.sequence_id] = nd.node_id.to_s if nd.node && nd.node.visible?
      end
    end

    ordered_nodes.each do |nd_id|
      next unless nd_id && nd_id != "0"

      node_el = XML::Node.new "nd"
      node_el["ref"] = nd_id
      el << node_el
    end

    add_tags_to_xml_node(el, way_tags)

    el
  end

  def nds
    @nds ||= way_nodes.collect(&:node_id)
  end

  def tags
    @tags ||= Hash[way_tags.collect { |t| [t.k, t.v] }]
  end

  attr_writer :nds

  attr_writer :tags

  def add_nd_num(n)
    @nds ||= []
    @nds << n.to_i
  end

  def add_tag_keyval(k, v)
    @tags ||= {}

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    raise OSM::APIDuplicateTagsError.new("way", id, k) if @tags.include? k

    @tags[k] = v
  end

  ##
  # the integer coords (i.e: unscaled) bounding box of the way, assuming
  # straight line segments.
  def bbox
    lons = nodes.collect(&:longitude)
    lats = nodes.collect(&:latitude)
    BoundingBox.new(lons.min, lats.min, lons.max, lats.max)
  end

  def update_from(new_way, user)
    Way.transaction do
      lock!
      check_consistency(self, new_way, user)
      raise OSM::APIPreconditionFailedError, "Cannot update way #{id}: data is invalid." unless new_way.preconditions_ok?(nds)

      self.changeset_id = new_way.changeset_id
      self.changeset = new_way.changeset
      self.tags = new_way.tags
      self.nds = new_way.nds
      self.visible = true
      save_with_history!
    end
  end

  def create_with_history(user)
    check_create_consistency(self, user)
    raise OSM::APIPreconditionFailedError, "Cannot create way: data is invalid." unless preconditions_ok?
    self.version = 0
    self.visible = true
    save_with_history!
  end

  def preconditions_ok?(old_nodes = [])
    return false if nds.empty?
    raise OSM::APITooManyWayNodesError.new(id, nds.length, MAX_NUMBER_OF_WAY_NODES) if nds.length > MAX_NUMBER_OF_WAY_NODES

    # check only the new nodes, for efficiency - old nodes having been checked last time and can't
    # be deleted when they're in-use.
    new_nds = (nds - old_nodes).sort.uniq

    unless new_nds.empty?
      # NOTE: nodes are locked here to ensure they can't be deleted before
      # the current transaction commits.
      db_nds = Node.where(:id => new_nds, :visible => true).lock("for share")

      if db_nds.length < new_nds.length
        missing = new_nds - db_nds.collect(&:id)
        raise OSM::APIPreconditionFailedError, "Way #{id} requires the nodes with id in (#{missing.join(',')}), which either do not exist, or are not visible."
      end
    end

    true
  end

  def delete_with_history!(new_way, user)
    raise OSM::APIAlreadyDeletedError.new("way", new_way.id) unless visible

    # need to start the transaction here, so that the database can
    # provide repeatable reads for the used-by checks. this means it
    # shouldn't be possible to get race conditions.
    Way.transaction do
      lock!
      check_consistency(self, new_way, user)
      rels = Relation.joins(:relation_members).where(:visible => true, :current_relation_members => { :member_type => "Way", :member_id => id }).order(:id)
      raise OSM::APIPreconditionFailedError, "Way #{id} is still used by relations #{rels.collect(&:id).join(',')}." unless rels.empty?

      self.changeset_id = new_way.changeset_id
      self.changeset = new_way.changeset

      self.tags = []
      self.nds = []
      self.visible = false
      save_with_history!
    end
  end

  ##
  # if any referenced nodes are placeholder IDs (i.e: are negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def fix_placeholders!(id_map, placeholder_id = nil)
    nds.map! do |node_id|
      if node_id < 0
        new_id = id_map[:node][node_id]
        raise OSM::APIBadUserInput, "Placeholder node not found for reference #{node_id} in way #{id.nil? ? placeholder_id : id}" if new_id.nil?
        new_id
      else
        node_id
      end
    end
  end

  private

  def save_with_history!
    t = Time.now.getutc

    self.version += 1
    self.timestamp = t

    # update the bounding box, note that this has to be done both before
    # and after the save, so that nodes from both versions are included in the
    # bbox. we use a copy of the changeset so that it isn't reloaded
    # later in the save.
    cs = changeset
    cs.update_bbox!(bbox) unless nodes.empty?

    Way.transaction do
      # clone the object before saving it so that the original is
      # still marked as dirty if we retry the transaction
      clone.save!

      tags = self.tags
      WayTag.where(:way_id => id).delete_all
      tags.each do |k, v|
        tag = WayTag.new
        tag.way_id = id
        tag.k = k
        tag.v = v
        tag.save!
      end

      nds = self.nds
      WayNode.where(:way_id => id).delete_all
      sequence = 1
      nds.each do |n|
        nd = WayNode.new
        nd.id = [id, sequence]
        nd.node_id = n
        nd.save!
        sequence += 1
      end

      old_way = OldWay.from_way(self)
      old_way.timestamp = t
      old_way.save_with_dependencies!

      # reload the way so that the nodes array points to the correct
      # new set of nodes.
      reload

      # update and commit the bounding box, now that way nodes
      # have been updated and we're in a transaction.
      cs.update_bbox!(bbox) unless nodes.empty?

      # tell the changeset we updated one element only
      cs.add_changes! 1

      cs.save!
    end
  end
end
