# == Schema Information
#
# Table name: relation_members
#
#  relation_id :bigint           not null, primary key
#  member_type :enum             not null
#  member_id   :bigint           not null
#  member_role :string           not null
#  version     :bigint           default(0), not null, primary key
#  sequence_id :integer          default(0), not null, primary key
#
# Indexes
#
#  relation_members_member_idx  (member_type,member_id)
#
# Foreign Keys
#
#  relation_members_id_fkey  ([relation_id, version] => relations[relation_id, version])
#

class OldRelationMember < ApplicationRecord
  self.table_name = "relation_members"

  belongs_to :old_relation, :foreign_key => [:relation_id, :version], :inverse_of => :old_members
  # A bit messy, referring to the current tables, should do for the data browser for now
  belongs_to :member, :polymorphic => true

  validates :member_role, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
end
