class RelationMember < ActiveRecord::Base
  set_table_name 'current_relation_members'  
  set_primary_keys :relation_id, :sequence_id

  belongs_to :relation
  belongs_to :member, :polymorphic => true
end
