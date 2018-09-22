# == Schema Information
#
# Table name: current_relations
#
#  id           :integer          not null, primary key
#  changeset_id :integer          not null
#  timestamp    :datetime         not null
#  visible      :boolean          not null
#  version      :integer          not null
#
# Indexes
#
#  current_relations_timestamp_idx  (timestamp)
#
# Foreign Keys
#
#  current_relations_changeset_id_fkey  (changeset_id => changesets.id)
#

class Relation < ActiveRecord::Base
  require "xml/libxml"

  include ConsistencyValidations
  include NotRedactable
  include ObjectMetadata

  self.table_name = "current_relations"

  belongs_to :changeset

  has_many :old_relations, -> { order(:version) }

  has_many :relation_members, -> { order(:sequence_id) }
  has_many :relation_tags

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
  scope :nodes, ->(*ids) { joins(:relation_members).where(:current_relation_members => { :member_type => "Node", :member_id => ids.flatten }) }
  scope :ways, ->(*ids) { joins(:relation_members).where(:current_relation_members => { :member_type => "Way", :member_id => ids.flatten }) }
  scope :relations, ->(*ids) { joins(:relation_members).where(:current_relation_members => { :member_type => "Relation", :member_id => ids.flatten }) }

  TYPES = %w[node way relation].freeze

  def self.from_xml(xml, create = false)
    p = XML::Parser.string(xml, :options => XML::Parser::Options::NOERROR)
    doc = p.parse

    doc.find("//osm/relation").each do |pt|
      return Relation.from_xml_node(pt, create)
    end
    raise OSM::APIBadXMLError.new("node", xml, "XML doesn't contain an osm/relation element.")
  rescue LibXML::XML::Error, ArgumentError => ex
    raise OSM::APIBadXMLError.new("relation", xml, ex.message)
  end

  def self.from_xml_node(pt, create = false)
    relation = Relation.new

    raise OSM::APIBadXMLError.new("relation", pt, "Version is required when updating") unless create || !pt["version"].nil?

    relation.version = pt["version"]
    raise OSM::APIBadXMLError.new("relation", pt, "Changeset id is missing") if pt["changeset"].nil?

    relation.changeset_id = pt["changeset"]

    unless create
      raise OSM::APIBadXMLError.new("relation", pt, "ID is required when updating") if pt["id"].nil?

      relation.id = pt["id"].to_i
      # .to_i will return 0 if there is no number that can be parsed.
      # We want to make sure that there is no id with zero anyway
      raise OSM::APIBadUserInput, "ID of relation cannot be zero when updating." if relation.id.zero?
    end

    # We don't care about the timestamp nor the visibility as these are either
    # set explicitly or implicit in the action. The visibility is set to true,
    # and manually set to false before the actual delete.
    relation.visible = true

    # Start with no tags
    relation.tags = {}

    # Add in any tags from the XML
    pt.find("tag").each do |tag|
      raise OSM::APIBadXMLError.new("relation", pt, "tag is missing key") if tag["k"].nil?
      raise OSM::APIBadXMLError.new("relation", pt, "tag is missing value") if tag["v"].nil?

      relation.add_tag_keyval(tag["k"], tag["v"])
    end

    # need to initialise the relation members array explicitly, as if this
    # isn't done for a new relation then @members attribute will be nil,
    # and the members will be loaded from the database instead of being
    # empty, as intended.
    relation.members = []

    pt.find("member").each do |member|
      # member_type =
      raise OSM::APIBadXMLError.new("relation", pt, "The #{member['type']} is not allowed only, #{TYPES.inspect} allowed") unless TYPES.include? member["type"]

      # member_ref = member['ref']
      # member_role
      member["role"] ||= "" # Allow  the upload to not include this, in which case we default to an empty string.
      relation.add_member(member["type"].classify, member["ref"], member["role"])
    end
    raise OSM::APIBadUserInput, "Some bad xml in relation" if relation.nil?

    relation
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node
    doc
  end

  def to_xml_node(changeset_cache = {}, user_display_name_cache = {})
    el = XML::Node.new "relation"
    el["id"] = id.to_s

    add_metadata_to_xml_node(el, self, changeset_cache, user_display_name_cache)

    relation_members.each do |member|
      member_el = XML::Node.new "member"
      member_el["type"] = member.member_type.downcase
      member_el["ref"] = member.member_id.to_s
      member_el["role"] = member.member_role
      el << member_el
    end

    add_tags_to_xml_node(el, relation_tags)

    el
  end

  # FIXME: is this really needed?
  def members
    @members ||= relation_members.map do |member|
      [member.member_type, member.member_id, member.member_role]
    end
  end

  def tags
    @tags ||= Hash[relation_tags.collect { |t| [t.k, t.v] }]
  end

  attr_writer :members

  attr_writer :tags

  def add_member(type, id, role)
    @members ||= []
    @members << [type, id.to_i, role]
  end

  def add_tag_keyval(k, v)
    @tags ||= {}

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    raise OSM::APIDuplicateTagsError.new("relation", id, k) if @tags.include? k

    @tags[k] = v
  end

  ##
  # updates the changeset bounding box to contain the bounding box of
  # the element with given +type+ and +id+. this only works with nodes
  # and ways at the moment, as they're the only elements to respond to
  # the :bbox call.
  def update_changeset_element(type, id)
    element = Kernel.const_get(type.capitalize).find(id)
    changeset.update_bbox! element.bbox
  end

  def delete_with_history!(new_relation, user)
    raise OSM::APIAlreadyDeletedError.new("relation", new_relation.id) unless visible

    # need to start the transaction here, so that the database can
    # provide repeatable reads for the used-by checks. this means it
    # shouldn't be possible to get race conditions.
    Relation.transaction do
      lock!
      check_consistency(self, new_relation, user)
      # This will check to see if this relation is used by another relation
      rel = RelationMember.joins(:relation).find_by("visible = ? AND member_type = 'Relation' and member_id = ? ", true, id)
      raise OSM::APIPreconditionFailedError, "The relation #{new_relation.id} is used in relation #{rel.relation.id}." unless rel.nil?

      self.changeset_id = new_relation.changeset_id
      self.tags = {}
      self.members = []
      self.visible = false
      save_with_history!
    end
  end

  def update_from(new_relation, user)
    Relation.transaction do
      lock!
      check_consistency(self, new_relation, user)
      raise OSM::APIPreconditionFailedError, "Cannot update relation #{id}: data or member data is invalid." unless new_relation.preconditions_ok?(members)

      self.changeset_id = new_relation.changeset_id
      self.changeset = new_relation.changeset
      self.tags = new_relation.tags
      self.members = new_relation.members
      self.visible = true
      save_with_history!
    end
  end

  def create_with_history(user)
    check_create_consistency(self, user)
    raise OSM::APIPreconditionFailedError, "Cannot create relation: data or member data is invalid." unless preconditions_ok?

    self.version = 0
    self.visible = true
    save_with_history!
  end

  def preconditions_ok?(good_members = [])
    # These are hastables that store an id in the index of all
    # the nodes/way/relations that have already been added.
    # If the member is valid and visible then we add it to the
    # relevant hash table, with the value true as a cache.
    # Thus if you have nodes with the ids of 50 and 1 already in the
    # relation, then the hash table nodes would contain:
    # => {50=>true, 1=>true}
    elements = { :node => {}, :way => {}, :relation => {} }

    # pre-set all existing members to good
    good_members.each { |m| elements[m[0].downcase.to_sym][m[1]] = true }

    members.each do |m|
      # find the hash for the element type or die
      hash = elements[m[0].downcase.to_sym]
      return false unless hash

      # unless its in the cache already
      next if hash.key? m[1]

      # use reflection to look up the appropriate class
      model = Kernel.const_get(m[0].capitalize)
      # get the element with that ID. and, if found, lock the element to
      # ensure it can't be deleted until after the current transaction
      # commits.
      element = model.lock("for share").find_by(:id => m[1])

      # and check that it is OK to use.
      raise OSM::APIPreconditionFailedError, "Relation with id #{id} cannot be saved due to #{m[0]} with id #{m[1]}" unless element && element.visible? && element.preconditions_ok?

      hash[m[1]] = true
    end

    true
  end

  ##
  # if any members are referenced by placeholder IDs (i.e: negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def fix_placeholders!(id_map, placeholder_id = nil)
    members.map! do |type, id, role|
      old_id = id.to_i
      if old_id < 0
        new_id = id_map[type.downcase.to_sym][old_id]
        raise OSM::APIBadUserInput, "Placeholder #{type} not found for reference #{old_id} in relation #{self.id.nil? ? placeholder_id : self.id}." if new_id.nil?

        [type, new_id, role]
      else
        [type, id, role]
      end
    end
  end

  private

  def save_with_history!
    t = Time.now.getutc

    self.version += 1
    self.timestamp = t

    Relation.transaction do
      # have to be a little bit clever here - to detect if any tags
      # changed then we have to monitor their before and after state.
      tags_changed = false

      # clone the object before saving it so that the original is
      # still marked as dirty if we retry the transaction
      clone.save!

      tags = self.tags.clone
      relation_tags.each do |old_tag|
        key = old_tag.k
        # if we can match the tags we currently have to the list
        # of old tags, then we never set the tags_changed flag. but
        # if any are different then set the flag and do the DB
        # update.
        if tags.key? key
          tags_changed |= (old_tag.v != tags[key])

          # remove from the map, so that we can expect an empty map
          # at the end if there are no new tags
          tags.delete key

        else
          # this means a tag was deleted
          tags_changed = true
        end
      end
      # if there are left-over tags then they are new and will have to
      # be added.
      tags_changed |= !tags.empty?
      RelationTag.where(:relation_id => id).delete_all
      self.tags.each do |k, v|
        tag = RelationTag.new
        tag.relation_id = id
        tag.k = k
        tag.v = v
        tag.save!
      end

      # same pattern as before, but this time we're collecting the
      # changed members in an array, as the bounding box updates for
      # elements are per-element, not blanked on/off like for tags.
      changed_members = []
      members = self.members.clone
      relation_members.each do |old_member|
        key = [old_member.member_type, old_member.member_id, old_member.member_role]
        i = members.index key
        if i.nil?
          changed_members << key
        else
          members.delete_at i
        end
      end
      # any remaining members must be new additions
      changed_members += members

      # update the members. first delete all the old members, as the new
      # members may be in a different order and i don't feel like implementing
      # a longest common subsequence algorithm to optimise this.
      members = self.members
      RelationMember.where(:relation_id => id).delete_all
      members.each_with_index do |m, i|
        mem = RelationMember.new
        mem.relation_id = id
        mem.sequence_id = i
        mem.member_type = m[0]
        mem.member_id = m[1]
        mem.member_role = m[2]
        mem.save!
      end

      old_relation = OldRelation.from_relation(self)
      old_relation.timestamp = t
      old_relation.save_with_dependencies!

      # update the bbox of the changeset and save it too.
      # discussion on the mailing list gave the following definition for
      # the bounding box update procedure of a relation:
      #
      # adding or removing nodes or ways from a relation causes them to be
      # added to the changeset bounding box. adding a relation member or
      # changing tag values causes all node and way members to be added to the
      # bounding box. this is similar to how the map call does things and is
      # reasonable on the assumption that adding or removing members doesn't
      # materially change the rest of the relation.
      any_relations =
        changed_members.collect { |_id, type| type == "relation" }
                       .inject(false) { |acc, elem| acc || elem }

      update_members = if tags_changed || any_relations
                         # add all non-relation bounding boxes to the changeset
                         # FIXME: check for tag changes along with element deletions and
                         # make sure that the deleted element's bounding box is hit.
                         self.members
                       else
                         changed_members
                       end
      update_members.each do |type, id, _role|
        update_changeset_element(type, id) if type != "Relation"
      end

      # tell the changeset we updated one element only
      changeset.add_changes! 1

      # save the (maybe updated) changeset bounding box
      changeset.save!
    end
  end
end
