class CorrectRelationMembersPrimaryKey < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    alter_primary_key :current_relation_members, [:relation_id, :sequence_id], :algorithm => :concurrently
    alter_primary_key :relation_members, [:relation_id, :version, :sequence_id], :algorithm => :concurrently
  end

  def down
    alter_primary_key :relation_members, [:relation_id, :version, :member_type, :member_id, :member_role, :sequence_id], :algorithm => :concurrently
    alter_primary_key :current_relation_members, [:relation_id, :member_type, :member_id, :member_role, :sequence_id], :algorithm => :concurrently
  end
end
