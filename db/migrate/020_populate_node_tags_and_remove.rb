require "migrate"

class PopulateNodeTagsAndRemove < ActiveRecord::Migration
  def self.up
    have_nodes = select_value("SELECT count(*) FROM current_nodes").to_i != 0

    if have_nodes
      prefix = File.join Dir.tmpdir, "020_populate_node_tags_and_remove.#{$PROCESS_ID}."

      cmd = "db/migrate/020_populate_node_tags_and_remove_helper"
      src = "#{cmd}.c"
      if !File.exist?(cmd) || File.mtime(cmd) < File.mtime(src)
        system("cc -O3 -Wall `mysql_config --cflags --libs` " +
          "#{src} -o #{cmd}") || fail
      end

      conn_opts = ActiveRecord::Base.connection.instance_eval { @connection_options }
      args = conn_opts.map(&:to_s) + [prefix]
      fail "#{cmd} failed" unless system cmd, *args

      tempfiles = %w(nodes node_tags current_nodes current_node_tags)
                  .map { |base| prefix + base }
      nodes, node_tags, current_nodes, current_node_tags = tempfiles
    end

    execute "TRUNCATE nodes"
    remove_column :nodes, :tags
    remove_column :current_nodes, :tags

    add_column :nodes, :version, :bigint, :null => false

    create_table :current_node_tags, :id => false do |t|
      t.column :id,          :bigint, :null => false
      t.column :k,	     :string, :default => "", :null => false
      t.column :v,	     :string, :default => "", :null => false
    end

    create_table :node_tags, :id => false do |t|
      t.column :id,          :bigint, :null => false
      t.column :version,     :bigint, :null => false
      t.column :k,	     :string, :default => "", :null => false
      t.column :v,	     :string, :default => "", :null => false
    end

    # now get the data back
    csvopts = "FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\\n'"

    if have_nodes
      execute "LOAD DATA INFILE '#{nodes}' INTO TABLE nodes #{csvopts} (id, latitude, longitude, user_id, visible, timestamp, tile, version)"
      execute "LOAD DATA INFILE '#{node_tags}' INTO TABLE node_tags #{csvopts} (id, version, k, v)"
      execute "LOAD DATA INFILE '#{current_nodes}' INTO TABLE current_nodes #{csvopts} (id, latitude, longitude, user_id, visible, timestamp, tile)"
      execute "LOAD DATA INFILE '#{current_node_tags}' INTO TABLE current_node_tags #{csvopts} (id, k, v)"
    end

    tempfiles.each { |fn| File.unlink fn } if have_nodes
  end

  def self.down
    fail ActiveRecord::IrreversibleMigration
    #    add_column :nodes, "tags", :text, :default => "", :null => false
    #    add_column :current_nodes, "tags", :text, :default => "", :null => false
  end
end
