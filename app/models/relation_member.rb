class RelationMember < ActiveRecord::Base
  self.table_name = "current_relation_members"
  self.primary_keys = "relation_id", "sequence_id"

  belongs_to :relation
  belongs_to :member, :polymorphic => true
end
