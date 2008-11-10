class OrderRelationMembers < ActiveRecord::Migration
  def self.up
    # add sequence column. rails won't let us define an ordering here,
    # as defaults must be constant.
    add_column(:relation_members, :sequence_id, :integer,
               :default => 0, :null => false)

    # update the sequence column with default (partial) ordering by 
    # element ID. the sequence ID is a smaller int type, so we can't
    # just copy the member_id.
    ActiveRecord::Base.connection().execute("update relation_members set sequence_id = mod(member_id, 16384)")

    # need to update the primary key to include the sequence number, 
    # otherwise the primary key will barf when we have repeated members.
    # mysql barfs on this anyway, so we need a single command. this may
    # not work in postgres... needs testing.
    ActiveRecord::Base.connection().execute("alter table relation_members drop primary key, add primary key (id, version, member_type, member_id, member_role, sequence_id)")

    # do the same for the current tables
    add_column(:current_relation_members, :sequence_id, :integer,
               :default => 0, :null => false)
    ActiveRecord::Base.connection().execute("update current_relation_members set sequence_id = mod(member_id, 16384)")
    ActiveRecord::Base.connection().execute("alter table current_relation_members drop primary key, add primary key (id, member_type, member_id, member_role, sequence_id)")
  end

  def self.down
    ActiveRecord::Base.connection().execute("alter table current_relation_members drop primary key, add primary key (id, member_type, member_id, member_role)")
    remove_column :relation_members, :sequence_id

    ActiveRecord::Base.connection().execute("alter table relation_members drop primary key, add primary key (id, version, member_type, member_id, member_role)")
    remove_column :current_relation_members, :sequence_id
  end
end
