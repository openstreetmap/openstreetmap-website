require "migrate"

class KeyConstraints < ActiveRecord::Migration
  def self.up
    # Primary keys
    add_primary_key :current_node_tags, [:id, :k]
    add_primary_key :current_way_tags, [:id, :k]
    add_primary_key :current_relation_tags, [:id, :k]

    add_primary_key :node_tags, [:id, :version, :k]
    add_primary_key :way_tags, [:id, :version, :k]
    add_primary_key :relation_tags, [:id, :version, :k]

    add_primary_key :nodes, [:id, :version]

    # Remove indexes superseded by primary keys
    remove_index :current_way_tags, :name => :current_way_tags_id_idx
    remove_index :current_relation_tags, :name => :current_relation_tags_id_idx

    remove_index :way_tags, :name => :way_tags_id_version_idx
    remove_index :relation_tags, :name => :relation_tags_id_version_idx

    remove_index :nodes, :name => :nodes_uid_idx

    # Foreign keys (between ways, way_tags, way_nodes, etc.)
    add_foreign_key :current_node_tags, :current_nodes, :column => :id, :name => "current_node_tags_id_fkey"
    add_foreign_key :node_tags, :nodes, :column => [:id, :version], :primary_key => [:id, :version], :name => "node_tags_id_fkey"

    add_foreign_key :current_way_tags, :current_ways, :column => :id, :name => "current_way_tags_id_fkey"
    add_foreign_key :current_way_nodes, :current_ways, :column => :id, :name => "current_way_nodes_id_fkey"
    add_foreign_key :way_tags, :ways, :column => [:id, :version], :primary_key => [:id, :version], :name => "way_tags_id_fkey"
    add_foreign_key :way_nodes, :ways, :column => [:id, :version], :primary_key => [:id, :version], :name => "way_nodes_id_fkey"

    add_foreign_key :current_relation_tags, :current_relations, :column => :id, :name => "current_relation_tags_id_fkey"
    add_foreign_key :current_relation_members, :current_relations, :column => :id, :name => "current_relation_members_id_fkey"
    add_foreign_key :relation_tags, :relations, :column => [:id, :version], :primary_key => [:id, :version], :name => "relation_tags_id_fkey"
    add_foreign_key :relation_members, :relations, :column => [:id, :version], :primary_key => [:id, :version], :name => "relation_members_id_fkey"

    # Foreign keys (between different types of primitives)
    add_foreign_key :current_way_nodes, :current_nodes, :column => :node_id, :name => "current_way_nodes_node_id_fkey"

    # FIXME: We don't have foreign keys for relation members since the id
    # might point to a different table depending on the `type' column.
    # We'd probably need different current_relation_member_nodes,
    # current_relation_member_ways and current_relation_member_relations
    # tables for this to work cleanly.
  end

  def self.down
    fail ActiveRecord::IrreversibleMigration
  end
end
