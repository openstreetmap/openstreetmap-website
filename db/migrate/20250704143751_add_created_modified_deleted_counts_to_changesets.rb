# frozen_string_literal: true

class AddCreatedModifiedDeletedCountsToChangesets < ActiveRecord::Migration[8.0]
  def change
    add_column :changesets, :num_created_nodes, :integer, :default => 0, :null => false
    add_column :changesets, :num_modified_nodes, :integer, :default => 0, :null => false
    add_column :changesets, :num_deleted_nodes, :integer, :default => 0, :null => false

    add_column :changesets, :num_created_ways, :integer, :default => 0, :null => false
    add_column :changesets, :num_modified_ways, :integer, :default => 0, :null => false
    add_column :changesets, :num_deleted_ways, :integer, :default => 0, :null => false

    add_column :changesets, :num_created_relations, :integer, :default => 0, :null => false
    add_column :changesets, :num_modified_relations, :integer, :default => 0, :null => false
    add_column :changesets, :num_deleted_relations, :integer, :default => 0, :null => false
  end
end
