class Relation < ActiveRecord::Base
  require 'xml/libxml'
  
  include ConsistencyValidations
  
  set_table_name 'current_relations'

  belongs_to :changeset

  has_many :old_relations, :foreign_key => 'id', :order => 'version'

  has_many :relation_members, :foreign_key => 'id', :order => 'sequence_id'
  has_many :relation_tags, :foreign_key => 'id'

  has_many :containing_relation_members, :class_name => "RelationMember", :as => :member
  has_many :containing_relations, :class_name => "Relation", :through => :containing_relation_members, :source => :relation, :extend => ObjectFinder

  validates_presence_of :id, :on => :update
  validates_presence_of :timestamp,:version,  :changeset_id 
  validates_uniqueness_of :id
  validates_inclusion_of :visible, :in => [ true, false ]
  validates_numericality_of :id, :on => :update, :integer_only => true
  validates_numericality_of :changeset_id, :version, :integer_only => true
  validates_associated :changeset
  
  TYPES = ["node", "way", "relation"]

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.string(xml)
      doc = p.parse

      doc.find('//osm/relation').each do |pt|
        return Relation.from_xml_node(pt, create)
      end
    rescue LibXML::XML::Error, ArgumentError => ex
      raise OSM::APIBadXMLError.new("relation", xml, ex.message)
    end
  end

  def self.from_xml_node(pt, create=false)
    relation = Relation.new

    if !create and pt['id'] != '0'
      relation.id = pt['id'].to_i
    end

    raise OSM::APIBadXMLError.new("relation", pt, "You are missing the required changeset in the relation") if pt['changeset'].nil?
    relation.changeset_id = pt['changeset']

    # The follow block does not need to be executed because they are dealt with 
    # in create_with_history, update_from and delete_with_history
    if create
      relation.timestamp = Time.now.getutc
      relation.visible = true
      relation.version = 0
    else
      if pt['timestamp']
        relation.timestamp = Time.parse(pt['timestamp'])
      end
      relation.version = pt['version']
    end

    pt.find('tag').each do |tag|
      relation.add_tag_keyval(tag['k'], tag['v'])
    end

    pt.find('member').each do |member|
      #member_type = 
      logger.debug "each member"
      raise OSM::APIBadXMLError.new("relation", pt, "The #{member['type']} is not allowed only, #{TYPES.inspect} allowed") unless TYPES.include? member['type']
      logger.debug "after raise"
      #member_ref = member['ref']
      #member_role
      member['role'] ||= "" # Allow  the upload to not include this, in which case we default to an empty string.
      logger.debug member['role']
      relation.add_member(member['type'], member['ref'], member['role'])
    end
    raise OSM::APIBadUserInput.new("Some bad xml in relation") if relation.nil?

    return relation
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node(user_display_name_cache = nil)
    el1 = XML::Node.new 'relation'
    el1['id'] = self.id.to_s
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    el1['version'] = self.version.to_s
    el1['changeset'] = self.changeset_id.to_s

    user_display_name_cache = {} if user_display_name_cache.nil?
    
    if user_display_name_cache and user_display_name_cache.key?(self.changeset.user_id)
      # use the cache if available
    elsif self.changeset.user.data_public?
      user_display_name_cache[self.changeset.user_id] = self.changeset.user.display_name
    else
      user_display_name_cache[self.changeset.user_id] = nil
    end

    if not user_display_name_cache[self.changeset.user_id].nil?
      el1['user'] = user_display_name_cache[self.changeset.user_id]
      el1['uid'] = self.changeset.user_id.to_s
    end

    self.relation_members.each do |member|
      p=0
      #if visible_members
      #  # if there is a list of visible members then use that to weed out deleted segments
      #  if visible_members[member.member_type][member.member_id]
      #    p=1
      #  end
      #else
        # otherwise, manually go to the db to check things
        if member.member.visible?
          p=1
        end
      #end
      if p
        e = XML::Node.new 'member'
        e['type'] = member.member_type
        e['ref'] = member.member_id.to_s 
        e['role'] = member.member_role
        el1 << e
       end
    end

    self.relation_tags.each do |tag|
      e = XML::Node.new 'tag'
      e['k'] = tag.k
      e['v'] = tag.v
      el1 << e
    end
    return el1
  end 

  def self.find_for_nodes(ids, options = {})
    if ids.empty?
      return []
    else
      self.with_scope(:find => { :joins => "INNER JOIN current_relation_members ON current_relation_members.id = current_relations.id", :conditions => "current_relation_members.member_type = 'node' AND current_relation_members.member_id IN (#{ids.join(',')})" }) do
        return self.find(:all, options)
      end
    end
  end

  def self.find_for_ways(ids, options = {})
    if ids.empty?
      return []
    else
      self.with_scope(:find => { :joins => "INNER JOIN current_relation_members ON current_relation_members.id = current_relations.id", :conditions => "current_relation_members.member_type = 'way' AND current_relation_members.member_id IN (#{ids.join(',')})" }) do
        return self.find(:all, options)
      end
    end
  end

  def self.find_for_relations(ids, options = {})
    if ids.empty?
      return []
    else
      self.with_scope(:find => { :joins => "INNER JOIN current_relation_members ON current_relation_members.id = current_relations.id", :conditions => "current_relation_members.member_type = 'relation' AND current_relation_members.member_id IN (#{ids.join(',')})" }) do
        return self.find(:all, options)
      end
    end
  end

  # FIXME is this really needed?
  def members
    unless @members
      @members = Array.new
      self.relation_members.each do |member|
        @members += [[member.member_type,member.member_id,member.member_role]]
      end
    end
    @members
  end

  def tags
    unless @tags
      @tags = Hash.new
      self.relation_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  def members=(m)
    @members = m
  end

  def tags=(t)
    @tags = t
  end

  def add_member(type,id,role)
    @members = Array.new unless @members
    @members += [[type,id,role]]
  end

  def add_tag_keyval(k, v)
    @tags = Hash.new unless @tags

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    raise OSM::APIDuplicateTagsError.new("relation", self.id, k) if @tags.include? k

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
    unless self.visible
      raise OSM::APIAlreadyDeletedError.new
    end

    # need to start the transaction here, so that the database can 
    # provide repeatable reads for the used-by checks. this means it
    # shouldn't be possible to get race conditions.
    Relation.transaction do
      check_consistency(self, new_relation, user)
      # This will check to see if this relation is used by another relation
      if RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id", :conditions => [ "visible = ? AND member_type='relation' and member_id=? ", true, self.id ])
        raise OSM::APIPreconditionFailedError.new("The relation #{new_relation.id} is a used in another relation")
      end
      self.changeset_id = new_relation.changeset_id
      self.tags = {}
      self.members = []
      self.visible = false
      save_with_history!
    end
  end

  def update_from(new_relation, user)
    check_consistency(self, new_relation, user)
    if !new_relation.preconditions_ok?
      raise OSM::APIPreconditionFailedError.new
    end
    self.changeset_id = new_relation.changeset_id
    self.changeset = new_relation.changeset
    self.tags = new_relation.tags
    self.members = new_relation.members
    self.visible = true
    save_with_history!
  end
  
  def create_with_history(user)
    check_create_consistency(self, user)
    if !self.preconditions_ok?
      raise OSM::APIPreconditionFailedError.new
    end
    self.version = 0
    self.visible = true
    save_with_history!
  end

  def preconditions_ok?
    # These are hastables that store an id in the index of all 
    # the nodes/way/relations that have already been added.
    # If the member is valid and visible then we add it to the 
    # relevant hash table, with the value true as a cache.
    # Thus if you have nodes with the ids of 50 and 1 already in the
    # relation, then the hash table nodes would contain:
    # => {50=>true, 1=>true}
    elements = { :node => Hash.new, :way => Hash.new, :relation => Hash.new }
    self.members.each do |m|
      # find the hash for the element type or die
      hash = elements[m[0].to_sym] or return false

      # unless its in the cache already
      unless hash.key? m[1]
        # use reflection to look up the appropriate class
        model = Kernel.const_get(m[0].capitalize)

        # get the element with that ID
        element = model.find(m[1])

        # and check that it is OK to use.
        unless element and element.visible? and element.preconditions_ok?
          return false
        end
        hash[m[1]] = true
      end
    end

    return true
  rescue
    return false
  end

  # Temporary method to match interface to nodes
  def tags_as_hash
    return self.tags
  end

  ##
  # if any members are referenced by placeholder IDs (i.e: negative) then
  # this calling this method will fix them using the map from placeholders 
  # to IDs +id_map+. 
  def fix_placeholders!(id_map)
    self.members.map! do |type, id, role|
      old_id = id.to_i
      if old_id < 0
        new_id = id_map[type.to_sym][old_id]
        raise "invalid placeholder" if new_id.nil?
        [type, new_id, role]
      else
        [type, id, role]
      end
    end
  end

  private
  
  def save_with_history!
    Relation.transaction do
      # have to be a little bit clever here - to detect if any tags
      # changed then we have to monitor their before and after state.
      tags_changed = false

      t = Time.now.getutc
      self.version += 1
      self.timestamp = t
      self.save!

      tags = self.tags
      self.relation_tags.each do |old_tag|
        key = old_tag.k
        # if we can match the tags we currently have to the list
        # of old tags, then we never set the tags_changed flag. but
        # if any are different then set the flag and do the DB 
        # update.
        if tags.has_key? key 
          # rails 2.1 dirty handling should take care of making this
          # somewhat efficient... hopefully...
          old_tag.v = tags[key]
          tags_changed |= old_tag.changed?
          old_tag.save!

          # remove from the map, so that we can expect an empty map
          # at the end if there are no new tags
          tags.delete key

        else
          # this means a tag was deleted
          tags_changed = true
          RelationTag.delete_all ['id = ? and k = ?', self.id, old_tag.k]
        end
      end
      # if there are left-over tags then they are new and will have to
      # be added.
      tags_changed |= (not tags.empty?)
      tags.each do |k,v|
        tag = RelationTag.new
        tag.k = k
        tag.v = v
        tag.id = self.id
        tag.save!
      end
      
      # reload, so that all of the members are accessible in their
      # new state.
      self.reload

      # same pattern as before, but this time we're collecting the
      # changed members in an array, as the bounding box updates for
      # elements are per-element, not blanked on/off like for tags.
      changed_members = Array.new
      members = Hash.new
      self.members.each do |m|
        # should be: h[[m.id, m.type]] = m.role, but someone prefers arrays
        members[[m[1], m[0]]] = m[2]
      end
      relation_members.each do |old_member|
        key = [old_member.member_id.to_s, old_member.member_type]
        if members.has_key? key
          members.delete key
        else
          changed_members << key
        end
      end
      # any remaining members must be new additions
      changed_members += members.keys

      # update the members. first delete all the old members, as the new
      # members may be in a different order and i don't feel like implementing
      # a longest common subsequence algorithm to optimise this.
      members = self.members
      RelationMember.delete_all(:id => self.id)
      members.each_with_index do |m,i|
        mem = RelationMember.new
        mem.id = [self.id, i]
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
        changed_members.collect { |id,type| type == "relation" }.
        inject(false) { |b,s| b or s }

      if tags_changed or any_relations
        # add all non-relation bounding boxes to the changeset
        # FIXME: check for tag changes along with element deletions and
        # make sure that the deleted element's bounding box is hit.
        self.members.each do |type, id, role|
          if type != "relation"
            update_changeset_element(type, id)
          end
        end
      else
        # add only changed members to the changeset
        changed_members.each do |id, type|
          update_changeset_element(type, id)
        end
      end

      # tell the changeset we updated one element only
      changeset.add_changes! 1

      # save the (maybe updated) changeset bounding box
      changeset.save!
    end
  end

end
