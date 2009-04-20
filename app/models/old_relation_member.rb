class OldRelationMember < ActiveRecord::Base
  set_table_name 'relation_members'

  set_primary_keys :id, :version, :sequence_id
  belongs_to :relation, :foreign_key=> :id
end
