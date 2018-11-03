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

  attr_accessor :skip_uniqueness
  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }, :unless => :skip_uniqueness
  validates :version, :presence => true,
                      :numericality => { :integer_only => true }
  validates :changeset_id, :presence => true,
                           :numericality => { :integer_only => true }
  validates :timestamp, :presence => true
  validates :changeset, :associated => true, :unless => :skip_uniqueness
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

  ##
  # bulk updates the given +changeset+ bounding box to contain the bounding box of
  # the element with given +type+ and +ids+. this only works with nodes
  # and ways at the moment, as they're the only elements to respond to
  # the :bbox call.
  def self.update_changeset_element_bulk(changeset, type, ids)
    model = Kernel.const_get(type.capitalize)
    model.update_changeset_bbox_bulk(changeset, ids)
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

  def self.delete_with_history_bulk!(relations, changeset, if_unused = false)
    relation_hash = relations.collect { |r| [r.id, r] }.to_h
    skipped = {}
    # need to start the transaction here, so that the database can
    # provide repeatable reads for the used-by checks. this means it
    # shouldn't be possible to get race conditions.
    Relation.transaction do
      relation_ids = relation_hash.keys
      old_relations = Relation.select("id, version, visible").where(:id => relation_ids).lock
      raise ActiveRecord::RecordNotFound unless old_relations.length == relation_ids.length

      old_relations.each do |old|
        unless old.visible
          # already deleted
          raise OSM::APIAlreadyDeletedError.new("relation", old.id) unless if_unused

          # if-unused: ignore and do next.
          # return old db version to client.
          relation_hash[old.id].version = old.version
          skipped[old.id] = relation_hash[old.id]
          relation_hash.delete old.id
          next
        end
        # check if client version equals db version
        new = relation_hash[old.id]
        new.changeset = changeset
        old.check_consistency(old, new, changeset.user)
      end
      # discover relations referred by relations
      rel_members = RelationMember.select("member_id, relation_id").where(:member_type => "Relation", :member_id => relation_hash.keys).where.not(:relation_id => relation_hash.keys).group_by(&:member_id)
      raise OSM::APIPreconditionFailedError, "Relation #{rel_members.first[0]} is still used by relations #{rel_members.first[1].collect(&:relation_id).join(',')}." unless rel_members.empty? || if_unused

      rel_members.each_key do |id|
        skipped[id] = relation_hash[id]
        relation_hash.delete id
      end
      # modify columns to delete
      to_deletes = relation_hash.values
      to_deletes.each do |relation|
        relation.tags = {}
        relation.members = []
        relation.visible = false
      end
      save_with_history_bulk!(to_deletes, changeset)
    end
    skipped
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

  def self.update_from_bulk(relations, changeset)
    Relation.transaction do
      relations.sort_by!(&:id)
      relation_ids = relations.collect(&:id)
      old_relations = Relation.select("id, version").where(:id => relation_ids).order(:id).lock
      raise ActiveRecord::RecordNotFound unless old_relations.length == relation_ids.length

      relation_ids.length.times do |i|
        relations[i].changeset = changeset
        old_relations[i].check_consistency(old_relations[i], relations[i], changeset.user)
        relations[i].visible = true
      end
      old_members = RelationMember.select("member_type, member_id").where(:relation_id => relation_ids)
                                  .collect { |m| [m.member_type, m.member_id] }
      raise OSM::APIPreconditionFailedError, "Cannot update relations: data or member data is invalid." unless preconditions_bulk_ok?(relations, old_members)

      save_with_history_bulk!(relations, changeset)
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
      raise OSM::APIPreconditionFailedError, "Relation with id #{id} cannot be saved due to #{m[0]} with id #{m[1]}" unless element&.visible? && element&.preconditions_ok?

      hash[m[1]] = true
    end

    true
  end

  def self.preconditions_bulk_ok?(relations, good_members = [])
    # These are hastables that store an id in the index of all
    # the nodes/way/relations that have already been added.
    # If the member is valid and visible then we add it to the
    # relevant hash table, with the value true as a cache.
    # Thus if you have nodes with the ids of 50 and 1 already in the
    # relation, then the hash table nodes would contain:
    # => {50=>true, 1=>true}
    ids = { :node => [], :way => [], :relation => [] }
    # only save type and id
    all_members = relations.flat_map do |relation|
      relation.members.collect { |m| [m[0], m[1]] }
    end.uniq
    all_members -= good_members.collect { |m| [m[0], m[1]] }
    all_members.each do |m|
      model_sym = m[0].downcase.to_sym
      return false unless ids.key? model_sym

      ids[model_sym].append(m[1])
    end
    ids.each do |model_sym, member_ids|
      next if member_ids.empty?

      # use reflection to look up the appropriate class
      model = Kernel.const_get(model_sym.to_s.capitalize)
      elements = model.select("id").where(:id => member_ids, :visible => true).lock("for share")

      # model.preconditions_bulk_ok?(elements)
      missing_elements = member_ids - elements.collect(&:id)
      next if missing_elements.empty?

      # generate error message
      relations.each do |r|
        r.members.each do |m|
          raise OSM::APIPreconditionFailedError, "Relation with id #{r.id} cannot be saved due to #{m[0]} with id #{m[1]}" if (m[0].downcase.to_sym == model_sym) && missing_elements.any? { |me| me == m[1] }
        end
      end
    end
    true
  end

  def self.create_with_history_bulk(relations, changeset)
    raise OSM::APIPreconditionFailedError, "Cannot create relation: data or member data is invalid." unless preconditions_bulk_ok?(relations)

    relations.each do |relation|
      relation.version = 0
      relation.visible = true
    end
    save_with_history_bulk!(relations, changeset)
  end

  ##
  # if any members are referenced by placeholder IDs (i.e: negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def fix_placeholders!(id_map, placeholder_id = nil)
    members.map! do |type, id, role|
      old_id = id.to_i
      if old_id.negative?
        new_id = id_map[type.downcase.to_sym][old_id]
        raise OSM::APIBadUserInput, "Placeholder #{type} not found for reference #{old_id} in relation #{self.id.nil? ? placeholder_id : self.id}." if new_id.nil?

        [type, new_id, role]
      else
        [type, id, role]
      end
    end
  end

  ##
  # if any members are referenced by placeholder IDs (i.e: negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def fix_placeholders(id_map)
    members.map! do |type, id, role|
      old_id = id.to_i
      if old_id.negative?
        new_id = id_map[type.downcase.to_sym][old_id]
        return type, old_id if new_id.nil?

        [type, new_id, role]
      else
        [type, id, role]
      end
    end
    nil
  end

  def self.tags_changed?(old_tag_arr, new_tag_hash)
    # have to be a little bit clever here - to detect if any tags
    # changed then we have to monitor their before and after state.
    tags_changed = false
    temp_tags = new_tag_hash.clone
    old_tag_arr.each do |old_tag|
      key = old_tag.k
      # if we can match the tags we currently have to the list
      # of old tags, then we never set the tags_changed flag. but
      # if any are different then set the flag and do the DB
      # update.
      if temp_tags.key? key
        tags_changed |= (old_tag.v != temp_tags[key])

        # remove from the map, so that we can expect an empty map
        # at the end if there are no new tags
        temp_tags.delete key

      else
        # this means a tag was deleted
        tags_changed = true
      end
    end
    # if there are left-over tags then they are new and will have to
    # be added.
    tags_changed | !temp_tags.empty?
  end

  def self.get_changed_members(old_members, new_members)
    # same pattern as before, but this time we're collecting the
    # changed members in an array, as the bounding box updates for
    # elements are per-element, not blanked on/off like for tags.
    changed_members = []
    members = new_members.clone
    old_members.each do |old_member|
      key = [old_member.member_type, old_member.member_id, old_member.member_role]
      i = members.index key
      if i.nil?
        changed_members << key
      else
        members.delete_at i
      end
    end
    # any remaining members must be new additions
    changed_members + members
  end

  def self.any_relations?(changed_members)
    changed_members.collect { |type, _id, _role| type == "Relation" }
                   .inject(false) { |acc, elem| acc || elem }
  end

  private

  def save_with_history!
    t = Time.now.getutc

    self.version += 1
    self.timestamp = t

    Relation.transaction do
      # clone the object before saving it so that the original is
      # still marked as dirty if we retry the transaction
      clone.save!

      tags_changed = Relation.tags_changed?(relation_tags, tags)
      RelationTag.where(:relation_id => id).delete_all
      tags.each do |k, v|
        tag = RelationTag.new
        tag.relation_id = id
        tag.k = k
        tag.v = v
        tag.save!
      end

      # same pattern as before, but this time we're collecting the
      # changed members in an array, as the bounding box updates for
      # elements are per-element, not blanked on/off like for tags.
      changed_members = Relation.get_changed_members(relation_members, members)

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
      any_relations = Relation.any_relations?(changed_members)

      # if the relation is being deleted tags_changed will be true and members empty
      # so we need to use changed_members to create a correct bounding box
      update_members = if visible && (tags_changed || any_relations)
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

  class << self
    private

    def save_with_history_bulk!(relations, changeset)
      # get old data before save
      relation_ids = relations.collect(&:id)
      old_tags = RelationTag.where(:relation_id => relation_ids).group_by(&:relation_id)
      old_members = RelationMember.where(:relation_id => relation_ids).group_by(&:relation_id)
      update_members = []
      relations.each do |relation|
        tags_changed = tags_changed?(old_tags[relation.id] || [], relation.tags)
        changed_members = get_changed_members(old_members[relation.id] || [], relation.members)
        any_relations = any_relations?(changed_members)
        update_members += (tags_changed || any_relations ? relation.members : changed_members)
      end
      t = Time.now.getutc
      Relation.transaction do
        clones = relations.collect do |relation|
          relation.version += 1
          relation.timestamp = t
          relation.skip_uniqueness = true
          relation.clone
        end
        Relation.import clones, :on_duplicate_key_update => [:changeset_id, :timestamp, :visible, :version]
        relation_ids = relations.collect(&:id)
        RelationTag.where(:relation_id => relation_ids).delete_all
        tag_values = relations.flat_map do |relation|
          relation.tags.collect do |k, v|
            rt = RelationTag.new(:relation_id => relation.id, :k => k, :v => v)
            rt.skip_uniqueness = true
            rt
          end
        end
        RelationTag.import tag_values

        RelationMember.where(:relation_id => relation_ids).delete_all
        member_values = relations.flat_map do |relation|
          sequence = 0
          relation.members.collect do |m|
            [relation.id, m[0], m[1], m[2], sequence += 1]
          end
        end
        member_columns = [:relation_id, :member_type, :member_id, :member_role, :sequence_id]
        RelationMember.import member_columns, member_values, :validate => false

        old_relations = relations.collect do |relation|
          OldRelation.from_relation(relation)
        end
        OldRelation.save_with_dependencies_bulk!(old_relations)

        update_members.group_by { |m| m[0] }.each do |type, elements|
          update_changeset_element_bulk(changeset, type, elements.collect { |e| e[1] }) if type != "Relation"
        end

        # tell the changeset we updated one element only
        changeset.add_changes! relations.length

        # save the (maybe updated) changeset bounding box
        changeset.save!
      end
    end
  end
end
