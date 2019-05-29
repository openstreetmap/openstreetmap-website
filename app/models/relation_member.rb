# == Schema Information
#
# Table name: current_relation_members
#
#  relation_id :bigint(8)        not null, primary key
#  member_type :enum             not null
#  member_id   :bigint(8)        not null
#  member_role :string           not null
#  sequence_id :integer          default(0), not null, primary key
#
# Indexes
#
#  current_relation_members_member_idx  (member_type,member_id)
#
# Foreign Keys
#
#  current_relation_members_id_fkey  (relation_id => current_relations.id)
#

class RelationMember < ActiveRecord::Base
  self.table_name = "current_relation_members"
  self.primary_keys = "relation_id", "sequence_id"

  belongs_to :relation, :foreign_key => :relation_id
  belongs_to :member, :polymorphic => true
end
