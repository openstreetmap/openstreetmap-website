class RenameIds < ActiveRecord::Migration[5.0]
  def change
    rename_column :changeset_tags, :id, :changeset_id
    rename_column :current_node_tags, :id, :node_id
    rename_column :nodes, :id, :node_id
    rename_column :node_tags, :id, :node_id
    rename_column :current_way_tags, :id, :way_id
    rename_column :current_way_nodes, :id, :way_id
    rename_column :ways, :id, :way_id
    rename_column :way_tags, :id, :way_id
    rename_column :way_nodes, :id, :way_id
    rename_column :current_relation_tags, :id, :relation_id
    rename_column :current_relation_members, :id, :relation_id
    rename_column :relations, :id, :relation_id
    rename_column :relation_tags, :id, :relation_id
    rename_column :relation_members, :id, :relation_id
  end
end
