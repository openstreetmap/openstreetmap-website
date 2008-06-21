class RelationMember < ActiveRecord::Base
  set_table_name 'current_relation_members'
  
  belongs_to :member, :polymorphic => true, :foreign_type => :member_class
  belongs_to :relation, :foreign_key => :id

  def after_find
    self[:member_class] = self.member_type.capitalize
  end

  def after_initialize
    self[:member_class] = self.member_type.capitalize
  end

  def before_save
    self.member_type = self[:member_class].downcase
  end

  def member_type=(type)
    self[:member_type] = type
    self[:member_class] = type.capitalize
  end
end
