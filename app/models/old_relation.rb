class OldRelation < ActiveRecord::Base
  set_table_name 'relations'

  belongs_to :user

  def self.from_relation(relation)
    old_relation = OldRelation.new
    old_relation.visible = relation.visible
    old_relation.user_id = relation.user_id
    old_relation.timestamp = relation.timestamp
    old_relation.id = relation.id
    old_relation.members = relation.members
    old_relation.tags = relation.tags
    return old_relation
  end

  def save_with_dependencies!

    # see comment in old_way.rb ;-)
    save!
    clear_aggregation_cache
    clear_association_cache
    @attributes.update(OldRelation.find(:first, :conditions => ['id = ? AND timestamp = ?', self.id, self.timestamp]).instance_variable_get('@attributes'))

    # ok, you can touch from here on

    self.tags.each do |k,v|
      tag = OldRelationTag.new
      tag.k = k
      tag.v = v
      tag.id = self.id
      tag.version = self.version
      tag.save!
    end

    i = 1
    self.members.each do |m|
      member = OldRelationMember.new
      member.id = self.id
      member.member_type = m[0]
      member.member_id = m[1]
      member.member_role = m[2]
      member.version = self.version
      member.save!
    end
  end

  def members
    unless @members
        @members = Array.new
        OldRelationMember.find(:all, :conditions => ["id = ? AND version = ?", self.id, self.version]).each do |m|
            @members += [[m.type,m.id,m.role]]
        end
    end
    @members
  end

  def tags
    unless @tags
        @tags = Hash.new
        OldRelationTag.find(:all, :conditions => ["id = ? AND version = ?", self.id, self.version]).each do |tag|
            @tags[tag.k] = tag.v
        end
    end
    @tags = Hash.new unless @tags
    @tags
  end

  def members=(s)
    @members = s
  end

  def tags=(t)
    @tags = t
  end

#  has_many :relation_segments, :class_name => 'OldRelationSegment', :foreign_key => 'id'
#  has_many :relation_tags, :class_name => 'OldRelationTag', :foreign_key => 'id'

  def old_members
    OldRelationMember.find(:all, :conditions => ['id = ? AND version = ?', self.id, self.version])    
  end

  def old_tags
    OldRelationTag.find(:all, :conditions => ['id = ? AND version = ?', self.id, self.version])    
  end

  def to_xml_node
    el1 = XML::Node.new 'relation'
    el1['id'] = self.id.to_s
    el1['visible'] = self.visible.to_s
    el1['timestamp'] = self.timestamp.xmlschema
    el1['user'] = self.user.display_name if self.user.data_public?
    
    self.old_members.each do |member|
      e = XML::Node.new 'member'
      e['type'] = member.member_type.to_s
      e['ref'] = member.member_id.to_s # "id" is considered uncool here as it should be unique in XML
      e['role'] = member.member_role.to_s
      el1 << e
    end
 
    self.old_tags.each do |tag|
      e = XML::Node.new 'tag'
      e['k'] = tag.k
      e['v'] = tag.v
      el1 << e
    end
    return el1
  end 
end
