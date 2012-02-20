class OldRelationMember < ActiveRecord::Base
  self.table_name = "relation_members"
  self.primary_keys = "relation_id", "version", "sequence_id"

  belongs_to :old_relation, :foreign_key => [:relation_id, :version]
  # A bit messy, referring to the current tables, should do for the data browser for now
  belongs_to :member, :polymorphic => true
end
