class AddPrimaryKeyOnNodesIdVersion < ActiveRecord::Migration

  #Migration will fail to run unless rake db:node_version has been run previously
  def self.up
    add_primary_key "nodes", ["id", "version"] 
  end

  def self.down
  end
end
