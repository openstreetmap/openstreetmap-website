class RelationMember < ActiveRecord::Base
  set_table_name 'current_relation_members'
  
  set_primary_keys :id, :sequence_id

  belongs_to :member, :polymorphic => true
  belongs_to :relation, :foreign_key => :id

  after_find :set_class_from_type
  after_initialize :set_class_from_type
  before_save :set_type_from_class

  def member_type=(type)
    self[:member_type] = type
    self[:member_class] = type.capitalize
  end

private

  def set_class_from_type
    self[:member_class] = self.member_type.classify unless self.member_type.nil?
  end

  def set_type_from_class
    self.member_type = self[:member_class].classify
  end
end
