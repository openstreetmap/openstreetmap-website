require 'migrate'

class AddChangesets < ActiveRecord::Migration
  @@conv_user_tables = ['current_nodes',
  'current_relations', 'current_ways', 'nodes', 'relations', 'ways' ]
  
  def self.up
    create_table "changesets", innodb_table do |t|
      t.column "id",             :bigint_pk,              :null => false
      t.column "user_id",        :bigint,   :limit => 20, :null => false
      t.column "created_at",     :datetime,               :null => false
      t.column "open",           :boolean,                :null => false, :default => true
      t.column "min_lat",        :integer,                :null => true
      t.column "max_lat",        :integer,                :null => true
      t.column "min_lon",        :integer,                :null => true
      t.column "max_lon",        :integer,                :null => true
    end

    create_table "changeset_tags", innodb_table do |t|
      t.column "id", :bigint, :limit => 64, :null => false
      t.column "k",  :string, :default => "", :null => false
      t.column "v",  :string, :default => "", :null => false
    end

    add_index "changeset_tags", ["id"], :name => "changeset_tags_id_idx"
    
    #
    # Initially we will have one changeset for every user containing 
    # all edits up to the API change,  
    # all the changesets will have the id of the user that made them.
    # We need to generate a changeset for each user in the database
    execute "INSERT INTO changesets (id, user_id, created_at, open)" + 
      "SELECT id, id, creation_time, false from users;"

    @@conv_user_tables.each { |tbl|
      rename_column tbl, :user_id, :changeset_id
      #foreign keys too
      add_foreign_key tbl, [:changeset_id], :changesets, [:id]
    }
  end

  def self.down
    # It's not easy to generate the user ids from the changesets
    raise ActiveRecord::IrreversibleMigration
    #drop_table "changesets"
    #drop_table "changeset_tags"
  end
end
