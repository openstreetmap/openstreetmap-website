# == Schema Information
#
# Table name: relation_members
#
#  relation_id :bigint(8)        default(0), not null, primary key
#  member_type :enum             not null
#  member_id   :bigint(8)        not null
#  member_role :string           not null
#  version     :bigint(8)        default(0), not null, primary key
#  sequence_id :integer          default(0), not null, primary key
#
# Indexes
#
#  relation_members_member_idx  (member_type,member_id)
#
# Foreign Keys
#
#  relation_members_id_fkey  (relation_id => relations.relation_id)
#

class OldRelationMember < ActiveRecord::Base
  self.table_name = "relation_members"
  self.primary_keys = "relation_id", "version", "sequence_id"

  belongs_to :old_relation, :foreign_key => [:relation_id, :version]
  # A bit messy, referring to the current tables, should do for the data browser for now
  belongs_to :member, :polymorphic => true
end
