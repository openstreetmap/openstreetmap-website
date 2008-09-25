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
      execute "UPDATE current_#{tbl} SET version = " +
	"(SELECT max(version) FROM #{tbl} WHERE #{tbl}.id = current_#{tbl}.id)"
    }
  end

  def self.down
    raise IrreversibleMigration.new
  end
end
