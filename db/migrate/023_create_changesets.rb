require "migrate"

class CreateChangesets < ActiveRecord::Migration
  @conv_user_tables = %w(current_nodes current_relations current_ways nodes relations ways)

  def self.up
    create_table "changesets", :id => false do |t|
      t.column "id",             :bigserial, :primary_key => true, :null => false
      t.column "user_id",        :bigint, :null => false
      t.column "created_at",     :datetime, :null => false
      t.column "min_lat",        :integer, :null => true
      t.column "max_lat",        :integer, :null => true
      t.column "min_lon",        :integer, :null => true
      t.column "max_lon",        :integer, :null => true
      t.column :closed_at, :datetime, :null => false
      t.column :num_changes, :integer, :null => false, :default => 0
    end
 
    add_index "changesets", ["created_at"], :name => "changesets_created_at_idx"
    add_index "changesets", ["closed_at"], :name => "changesets_closed_at_idx"
    add_index "changesets", %w(min_lat max_lat min_lon max_lon), :name => "changesets_bbox_idx", :using => "GIST"
    add_index :changesets, [:user_id, :id], :name => "changesets_user_id_id_idx"
  

    create_table "changeset_tags", :id => false do |t|
      t.column "changeset_id", :bigint, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    add_index "changeset_tags", ["changeset_id"], :name => "changeset_tags_id_idx"

    #
    # Initially we will have one changeset for every user containing
    # all edits up to the API change,
    # all the changesets will have the id of the user that made them.
    # We need to generate a changeset for each user in the database
 
    @conv_user_tables.each do |tbl|
      rename_column tbl, :user_id, :changeset_id
      # foreign keys too
      add_foreign_key tbl, :changesets, :name => "#{tbl}_changeset_id_fkey"
    end
    add_index "nodes", ["changeset_id"], :name => "nodes_changeset_id_idx"
    add_index "ways", ["changeset_id"], :name => "ways_changeset_id_idx"
    add_index "relations", ["changeset_id"], :name => "relations_changeset_id_idx"

    add_index :changesets, [:user_id, :created_at], :name => "changesets_user_id_created_at_idx"
 

  end

  def self.down
    # It's not easy to generate the user ids from the changesets
    raise ActiveRecord::IrreversibleMigration
    # drop_table "changesets"
    # drop_table "changeset_tags"
  end
end
