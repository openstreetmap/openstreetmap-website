require 'migrate'

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
    add_foreign_key :current_node_tags, [:id], :current_nodes
    add_foreign_key :node_tags, [:id, :version], :nodes

    add_foreign_key :current_way_tags, [:id], :current_ways
    add_foreign_key :current_way_nodes, [:id], :current_ways
    add_foreign_key :way_tags, [:id, :version], :ways
    add_foreign_key :way_nodes, [:id, :version], :ways

    add_foreign_key :current_relation_tags, [:id], :current_relations
    add_foreign_key :current_relation_members, [:id], :current_relations
    add_foreign_key :relation_tags, [:id, :version], :relations
    add_foreign_key :relation_members, [:id, :version], :relations

    # Foreign keys (between different types of primitives)
    add_foreign_key :current_way_nodes, [:node_id], :current_nodes, [:id]

    # FIXME: We don't have foreign keys for relation members since the id
    # might point to a different table depending on the `type' column.
    # We'd probably need different current_relation_member_nodes,
    # current_relation_member_ways and current_relation_member_relations
    # tables for this to work cleanly.
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
