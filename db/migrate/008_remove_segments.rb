require 'migrate'

class RemoveSegments < ActiveRecord::Migration
  def self.up
    have_segs = select_value("SELECT count(*) FROM current_segments").to_i != 0

    if have_segs
      prefix = File.join Dir.tmpdir, "008_remove_segments.#{$$}."

      cmd = "db/migrate/008_remove_segments_helper"
      src = "#{cmd}.cc"
      if not File.exists? cmd or File.mtime(cmd) < File.mtime(src) then
	system 'c++ -O3 -Wall `mysql_config --cflags --libs` ' +
	  "#{src} -o #{cmd}" or fail
      end

      conn_opts = ActiveRecord::Base.connection.
	instance_eval { @connection_options }
      args = conn_opts.map { |arg| arg.to_s } + [prefix]
      fail "#{cmd} failed" unless system cmd, *args

      tempfiles = ['ways', 'way_nodes', 'way_tags',
	'relations', 'relation_members', 'relation_tags'].
	map { |base| prefix + base }
      ways, way_nodes, way_tags,
	relations, relation_members, relation_tags = tempfiles
    end

    drop_table :segments
    drop_table :way_segments
    create_table :way_nodes, :id => false do |t|
      t.column :id,          :bigint, :null => false
      t.column :node_id,     :bigint, :null => false
      t.column :version,     :bigint, :null => false
      t.column :sequence_id, :bigint, :null => false
    end
    add_primary_key :way_nodes, [:id, :version, :sequence_id]

    drop_table :current_segments
    drop_table :current_way_segments
    create_table :current_way_nodes, :id => false do |t|
      t.column :id,          :bigint, :null => false
      t.column :node_id,     :bigint, :null => false
      t.column :sequence_id, :bigint, :null => false
    end
    add_primary_key :current_way_nodes, [:id, :sequence_id]
    add_index :current_way_nodes, [:node_id], :name => "current_way_nodes_node_idx"

    execute "TRUNCATE way_tags"
    execute "TRUNCATE ways"
    execute "TRUNCATE current_way_tags"
    execute "TRUNCATE current_ways"

    # now get the data back
    csvopts = "FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\\n'"

    tempfiles.each { |fn| File.chmod 0644, fn } if have_segs

    if have_segs
      execute "LOAD DATA INFILE '#{ways}' INTO TABLE ways #{csvopts} (id, user_id, timestamp) SET visible = 1, version = 1"
      execute "LOAD DATA INFILE '#{way_nodes}' INTO TABLE way_nodes #{csvopts} (id, node_id, sequence_id) SET version = 1"
      execute "LOAD DATA INFILE '#{way_tags}' INTO TABLE way_tags #{csvopts} (id, k, v) SET version = 1"

      execute "INSERT INTO current_ways SELECT id, user_id, timestamp, visible FROM ways"
      execute "INSERT INTO current_way_nodes SELECT id, node_id, sequence_id FROM way_nodes"
      execute "INSERT INTO current_way_tags SELECT id, k, v FROM way_tags"
    end

    if have_segs
      execute "LOAD DATA INFILE '#{relations}' INTO TABLE relations #{csvopts} (id, user_id, timestamp) SET visible = 1, version = 1"
      execute "LOAD DATA INFILE '#{relation_members}' INTO TABLE relation_members #{csvopts} (id, member_type, member_id, member_role) SET version = 1"
      execute "LOAD DATA INFILE '#{relation_tags}' INTO TABLE relation_tags #{csvopts} (id, k, v) SET version = 1"

      # FIXME: This will only work if there were no relations before the
      # migration!
      execute "INSERT INTO current_relations SELECT id, user_id, timestamp, visible FROM relations"
      execute "INSERT INTO current_relation_members SELECT id, member_type, member_id, member_role FROM relation_members"
      execute "INSERT INTO current_relation_tags SELECT id, k, v FROM relation_tags"
    end

    tempfiles.each { |fn| File.unlink fn } if have_segs
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
