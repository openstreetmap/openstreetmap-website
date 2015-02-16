require 'migrate'

class OrderRelationMembers < ActiveRecord::Migration
  def self.up
    # add sequence column. rails won't let us define an ordering here,
    # as defaults must be constant.
    add_column(:relation_members, :sequence_id, :integer,
               :default => 0, :null => false)

    # update the sequence column with default (partial) ordering by
    # element ID. the sequence ID is a smaller int type, so we can't
    # just copy the member_id.
    execute("update relation_members set sequence_id = mod(member_id, 16384)")

    # need to update the primary key to include the sequence number,
    # otherwise the primary key will barf when we have repeated members.
    # mysql barfs on this anyway, so we need a single command. this may
    # not work in postgres... needs testing.
    alter_primary_key("relation_members", [:id, :version, :member_type, :member_id, :member_role, :sequence_id])

    # do the same for the current tables
    add_column(:current_relation_members, :sequence_id, :integer,
               :default => 0, :null => false)
    execute("update current_relation_members set sequence_id = mod(member_id, 16384)")
    alter_primary_key("current_relation_members", [:id, :member_type, :member_id, :member_role, :sequence_id])
  end

  def self.down
    alter_primary_key("current_relation_members", [:id, :member_type, :member_id, :member_role])
    remove_column :relation_members, :sequence_id

    alter_primary_key("relation_members", [:id, :version, :member_type, :member_id, :member_role])
    remove_column :current_relation_members, :sequence_id
  end
end
