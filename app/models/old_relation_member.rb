class OldRelationMember < ActiveRecord::Base
  set_table_name 'relation_members'

  set_primary_keys :id, :version, :sequence_id
  belongs_to :relation, :foreign_key=> :id
  # A bit messy, referring to the current tables, should do for the data browser for now
  belongs_to :member, :polymorphic => true
end
