require "migrate"

class AddRelations < ActiveRecord::Migration
  def self.up
    # enums work like strings but are more efficient
    create_enumeration :nwr_enum, %w(Node Way Relation)

    # a relation can have members much like a way can have nodes.
    # differences:
    # way: only nodes / relation: any kind of member
    # way: ordered sequence of nodes / relation: free-form "role" string
    create_table "current_relation_members", :id => false do |t|
      t.column "id",          :bigint, :null => false
      t.column "member_type", :nwr_enum, :null => false
      t.column "member_id",   :bigint, :null => false
      t.column "member_role", :string
    end

    add_primary_key "current_relation_members", %w(id member_type member_id member_role)
    add_index "current_relation_members", %w(member_type member_id), :name => "current_relation_members_member_idx"
    # the following is obsolete given the primary key, is it not?
    # add_index "current_relation_members", ["id"], :name => "current_relation_members_id_idx"
    create_table "current_relation_tags", :id => false do |t|
      t.column "id", :bigint, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    add_index "current_relation_tags", ["id"], :name => "current_relation_tags_id_idx"
    add_index "current_relation_tags", "v", :name => "current_relation_tags_v_idx"

    create_table "current_relations", :id => false do |t|
      t.column "id",        :bigserial, :primary_key => true, :null => false
      t.column "user_id",   :bigint, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "visible",   :boolean, :null => false
    end

    create_table "relation_members", :id => false do |t|
      t.column "id",          :bigint, :default => 0, :null => false
      t.column "member_type", :nwr_enum, :null => false
      t.column "member_id",   :bigint, :null => false
      t.column "member_role", :string
      t.column "version",     :bigint, :default => 0, :null => false
    end

    add_primary_key "relation_members", %w(id version member_type member_id member_role)
    add_index "relation_members", %w(member_type member_id), :name => "relation_members_member_idx"

    create_table "relation_tags", :id => false do |t|
      t.column "id",      :bigint, :default => 0, :null => false
      t.column "k",       :string, :null => false, :default => ""
      t.column "v",       :string, :null => false, :default => ""
      t.column "version", :bigint, :null => false
    end

    add_index "relation_tags", %w(id version), :name => "relation_tags_id_version_idx"

    create_table "relations", :id => false do |t|
      t.column "id",        :bigint, :null => false, :default => 0
      t.column "user_id",   :bigint, :null => false
      t.column "timestamp", :datetime, :null => false
      t.column "version",   :bigint, :null => false
      t.column "visible",   :boolean, :null => false, :default => true
    end

    add_primary_key "relations", %w(id version)
    add_index "relations", ["timestamp"], :name => "relations_timestamp_idx"
  end

  def self.down
    drop_table :relations
    drop_table :current_relations
    drop_table :relation_tags
    drop_table :current_relation_tags
    drop_table :relation_members
    drop_table :current_relation_members
    drop_enumeration :nwr_enum
  end
end
