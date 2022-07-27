class AddChangesetIndexes < ActiveRecord::Migration[4.2]
  def self.up
    add_index "nodes", ["changeset_id"], :name => "nodes_changeset_id_idx"
    add_index "ways", ["changeset_id"], :name => "ways_changeset_id_idx"
    add_index "relations", ["changeset_id"], :name => "relations_changeset_id_idx"
  end

  def self.down
    remove_index "relations", :name => "relations_changeset_id_idx"
    remove_index "ways", :name => "ways_changeset_id_idx"
    remove_index "nodes", :name => "nodes_changeset_id_idx"
  end
end
