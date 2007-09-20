class Relation < ActiveRecord::Base
  require 'xml/libxml'
  
  belongs_to :user

  has_many :relation_members, :foreign_key => 'id'
  has_many :relation_tags, :foreign_key => 'id'

  has_many :old_relations, :foreign_key => 'id', :order => 'version'

  set_table_name 'current_relations'

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.new
      p.string = xml
      doc = p.parse

      relation = Relation.new

      doc.find('//osm/relation').each do |pt|
        if !create and pt['id'] != '0'
          relation.id = pt['id'].to_i
        end

        if create
          relation.timestamp = Time.now
          relation.visible = true
        else
          if pt['timestamp']
            relation.timestamp = Time.parse(pt['timestamp'])
          end
        end

        pt.find('tag').each do |tag|
          relation.add_tag_keyval(tag['k'], tag['v'])
        end

        pt.find('member').each do |member|
          relation.add_member(member['type'], member['ref'], member['role'])
        end
      end
    rescue
      relation = nil
    end

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

    user_display_name_cache = {} if user_display_name_cache.nil?
    
    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?

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
    @tags[k] = v
  end

  def save_with_history!
    Relation.transaction do
      t = Time.now
      self.timestamp = t
      self.save!

      tags = self.tags

      RelationTag.delete_all(['id = ?', self.id])

      tags.each do |k,v|
	tag = RelationTag.new
	tag.k = k
	tag.v = v
	tag.id = self.id
	tag.save!
      end

      members = self.members

      RelationMember.delete_all(['id = ?', self.id])

      members.each do |n|
	mem = RelationMember.new
	mem.id = self.id
	mem.member_type = n[0];
	mem.member_id = n[1];
	mem.member_role = n[2];
	mem.save!
      end

      old_relation = OldRelation.from_relation(self)
      old_relation.timestamp = t
      old_relation.save_with_dependencies!
    end
  end

  def preconditions_ok?
    self.members.each do |m|
      if (m[0] == "node")
        n = Node.find(:first, :conditions => ["id = ?", m[1]])
        unless n and n.visible 
          return false
        end
      elsif (m[0] == "way")
        w = Way.find(:first, :conditions => ["id = ?", m[1]])
        unless w and w.visible and w.preconditions_ok?
          return false
        end
      elsif (m[0] == "relation")
        e = Relation.find(:first, :conditions => ["id = ?", m[1]])
        unless e and e.visible and e.preconditions_ok?
          return false
        end
      else
        return false
      end
    end
    return true
  rescue
    return false
  end

end
