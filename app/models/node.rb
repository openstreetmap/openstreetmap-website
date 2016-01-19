class Node < ActiveRecord::Base
  require "xml/libxml"

  include GeoRecord
  include ConsistencyValidations
  include NotRedactable
  include ObjectMetadata

  self.table_name = "current_nodes"

  belongs_to :changeset

  has_many :old_nodes, -> { order(:version) }

  has_many :way_nodes
  has_many :ways, :through => :way_nodes

  has_many :node_tags

  has_many :old_way_nodes
  has_many :ways_via_history, :class_name => "Way", :through => :old_way_nodes, :source => :way

  has_many :containing_relation_members, :class_name => "RelationMember", :as => :member
  has_many :containing_relations, :class_name => "Relation", :through => :containing_relation_members, :source => :relation

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :version, :presence => true,
                      :numericality => { :integer_only => true }
  validates :changeset_id, :presence => true,
                           :numericality => { :integer_only => true }
  validates :latitude, :presence => true,
                       :numericality => { :integer_only => true }
  validates :longitude, :presence => true,
                        :numericality => { :integer_only => true }
  validates :timestamp, :presence => true
  validates :changeset, :associated => true
  validates :visible, :inclusion => [true, false]

  validate :validate_position

  scope :visible, -> { where(:visible => true) }
  scope :invisible, -> { where(:visible => false) }

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add(:base, "Node is not in the world") unless in_world?
  end

  # Read in xml as text and return it's Node object representation
  def self.from_xml(xml, create = false)
    p = XML::Parser.string(xml)
    doc = p.parse

    doc.find("//osm/node").each do |pt|
      return Node.from_xml_node(pt, create)
    end
    fail OSM::APIBadXMLError.new("node", xml, "XML doesn't contain an osm/node element.")
  rescue LibXML::XML::Error, ArgumentError => ex
    raise OSM::APIBadXMLError.new("node", xml, ex.message)
  end

  def self.from_xml_node(pt, create = false)
    node = Node.new

    fail OSM::APIBadXMLError.new("node", pt, "lat missing") if pt["lat"].nil?
    fail OSM::APIBadXMLError.new("node", pt, "lon missing") if pt["lon"].nil?
    node.lat = OSM.parse_float(pt["lat"], OSM::APIBadXMLError, "node", pt, "lat not a number")
    node.lon = OSM.parse_float(pt["lon"], OSM::APIBadXMLError, "node", pt, "lon not a number")
    fail OSM::APIBadXMLError.new("node", pt, "Changeset id is missing") if pt["changeset"].nil?
    node.changeset_id = pt["changeset"].to_i

    fail OSM::APIBadUserInput.new("The node is outside this world") unless node.in_world?

    # version must be present unless creating
    fail OSM::APIBadXMLError.new("node", pt, "Version is required when updating") unless create || !pt["version"].nil?
    node.version = create ? 0 : pt["version"].to_i

    unless create
      fail OSM::APIBadXMLError.new("node", pt, "ID is required when updating.") if pt["id"].nil?
      node.id = pt["id"].to_i
      # .to_i will return 0 if there is no number that can be parsed.
      # We want to make sure that there is no id with zero anyway
      fail OSM::APIBadUserInput.new("ID of node cannot be zero when updating.") if node.id == 0
    end

    # We don't care about the time, as it is explicitly set on create/update/delete
    # We don't care about the visibility as it is implicit based on the action
    # and set manually before the actual delete
    node.visible = true

    # Start with no tags
    node.tags = {}

    # Add in any tags from the XML
    pt.find("tag").each do |tag|
      fail OSM::APIBadXMLError.new("node", pt, "tag is missing key") if tag["k"].nil?
      fail OSM::APIBadXMLError.new("node", pt, "tag is missing value") if tag["v"].nil?
      node.add_tag_key_val(tag["k"], tag["v"])
    end

    node
  end

  ##
  # the bounding box around a node, which is used for determining the changeset's
  # bounding box
  def bbox
    BoundingBox.new(longitude, latitude, longitude, latitude)
  end

  # Should probably be renamed delete_from to come in line with update
  def delete_with_history!(new_node, user)
    fail OSM::APIAlreadyDeletedError.new("node", new_node.id) unless visible

    # need to start the transaction here, so that the database can
    # provide repeatable reads for the used-by checks. this means it
    # shouldn't be possible to get race conditions.
    Node.transaction do
      lock!
      check_consistency(self, new_node, user)
      ways = Way.joins(:way_nodes).where(:visible => true, :current_way_nodes => { :node_id => id }).order(:id)
      fail OSM::APIPreconditionFailedError.new("Node #{id} is still used by ways #{ways.collect(&:id).join(",")}.") unless ways.empty?

      rels = Relation.joins(:relation_members).where(:visible => true, :current_relation_members => { :member_type => "Node", :member_id => id }).order(:id)
      fail OSM::APIPreconditionFailedError.new("Node #{id} is still used by relations #{rels.collect(&:id).join(",")}.") unless rels.empty?

      self.changeset_id = new_node.changeset_id
      self.tags = {}
      self.visible = false

      # update the changeset with the deleted position
      changeset.update_bbox!(bbox)

      save_with_history!
    end
  end

  def update_from(new_node, user)
    Node.transaction do
      lock!
      check_consistency(self, new_node, user)

      # update changeset first
      self.changeset_id = new_node.changeset_id
      self.changeset = new_node.changeset

      # update changeset bbox with *old* position first
      changeset.update_bbox!(bbox)

      # FIXME: logic needs to be double checked
      self.latitude = new_node.latitude
      self.longitude = new_node.longitude
      self.tags = new_node.tags
      self.visible = true

      # update changeset bbox with *new* position
      changeset.update_bbox!(bbox)

      save_with_history!
    end
  end

  def create_with_history(user)
    check_create_consistency(self, user)
    self.version = 0
    self.visible = true

    # update the changeset to include the new location
    changeset.update_bbox!(bbox)

    save_with_history!
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node
    doc
  end

  def to_xml_node(changeset_cache = {}, user_display_name_cache = {})
    el = XML::Node.new "node"
    el["id"] = id.to_s

    add_metadata_to_xml_node(el, self, changeset_cache, user_display_name_cache)

    if visible?
      el["lat"] = lat.to_s
      el["lon"] = lon.to_s
    end

    add_tags_to_xml_node(el, node_tags)

    el
  end

  def tags_as_hash
    tags
  end

  def tags
    @tags ||= Hash[node_tags.collect { |t| [t.k, t.v] }]
  end

  attr_writer :tags

  def add_tag_key_val(k, v)
    @tags = {} unless @tags

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    fail OSM::APIDuplicateTagsError.new("node", id, k) if @tags.include? k

    @tags[k] = v
  end

  ##
  # are the preconditions OK? this is mainly here to keep the duck
  # typing interface the same between nodes, ways and relations.
  def preconditions_ok?
    in_world?
  end

  ##
  # dummy method to make the interfaces of node, way and relation
  # more consistent.
  def fix_placeholders!(_id_map, _placeholder_id = nil)
    # nodes don't refer to anything, so there is nothing to do here
  end

  private

  def save_with_history!
    t = Time.now.getutc
    Node.transaction do
      self.version += 1
      self.timestamp = t
      save!

      # Create a NodeTag
      tags = self.tags
      NodeTag.delete_all(:node_id => id)
      tags.each do |k, v|
        tag = NodeTag.new
        tag.node_id = id
        tag.k = k
        tag.v = v
        tag.save!
      end

      # Create an OldNode
      old_node = OldNode.from_node(self)
      old_node.timestamp = t
      old_node.save_with_dependencies!

      # tell the changeset we updated one element only
      changeset.add_changes! 1

      # save the changeset in case of bounding box updates
      changeset.save!
    end
  end
end
