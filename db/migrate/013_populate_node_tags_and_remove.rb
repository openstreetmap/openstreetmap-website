class PopulateNodeTagsAndRemove < ActiveRecord::Migration
  def self.up
    #rake import 
    #commented out to stop people from breaking their db
#    remove_column :nodes, :tags
#    remove_column :current_nodes, :tags
  end

  def self.down
#    add_column :nodes, "tags", :text, :default => "", :null => false
#    add_column :current_nodes, "tags", :text, :default => "", :null => false
  end
end
