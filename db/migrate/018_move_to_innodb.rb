class MoveToInnodb < ActiveRecord::Migration
  @@conv_tables = ['nodes', 'ways', 'way_tags', 'way_nodes',
    'current_way_tags', 'relation_members',
    'relations', 'relation_tags', 'current_relation_tags']

  @@ver_tbl = ['nodes', 'ways', 'relations']

  def self.up
    execute 'DROP INDEX current_way_tags_v_idx ON current_way_tags'
    execute 'DROP INDEX current_relation_tags_v_idx ON current_relation_tags'

    @@ver_tbl.each { |tbl|
      change_column tbl, "version", :bigint, :limit => 20, :null => false
    }

    @@conv_tables.each { |tbl|
      execute "ALTER TABLE #{tbl} ENGINE = InnoDB"
    }

    @@ver_tbl.each { |tbl|
      add_column "current_#{tbl}", "version", :bigint, :limit => 20, :null => false
      # As the initial version of all nodes, ways and relations is 0, we set the 
      # current version to something less so that we can update the version in 
      # batches of 10000
      tbl.classify.constantize.update_all("version=-1")
      while tbl.classify.constantize.count(:conditions => {:version => -1}) > 0
        tbl.classify.constantize.update_all("version=(SELECT max(version) FROM #{tbl} WHERE #{tbl}.id = current_#{tbl}.id)", {:version => -1}, :limit => 10000)
      end
     # execute "UPDATE current_#{tbl} SET version = " +
      #  "(SELECT max(version) FROM #{tbl} WHERE #{tbl}.id = current_#{tbl}.id)"
        # The above update causes a MySQL error:
        # -- add_column("current_nodes", "version", :bigint, {:null=>false, :limit=>20})
        # -> 1410.9152s
        # -- execute("UPDATE current_nodes SET version = (SELECT max(version) FROM nodes WHERE nodes.id = current_nodes.id)")
        # rake aborted!
        # Mysql::Error: The total number of locks exceeds the lock table size: UPDATE current_nodes SET version = (SELECT max(version) FROM nodes WHERE nodes.id = current_nodes.id)

        # The above rails version will take longer, however will no run out of locks
    }
  end

  def self.down
    raise IrreversibleMigration.new
  end
end
