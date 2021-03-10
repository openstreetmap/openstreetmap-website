class AddMoreChangesetIndexes < ActiveRecord::Migration[4.2]
  def self.up
    enable_extension "btree_gist"

    add_index "changesets", ["created_at"], :name => "changesets_created_at_idx"
    add_index "changesets", ["closed_at"], :name => "changesets_closed_at_idx"
    add_index "changesets", %w[min_lat max_lat min_lon max_lon], :name => "changesets_bbox_idx", :using => "GIST"
  end

  def self.down
    remove_index "changesets", :name => "changesets_bbox_idx"
    remove_index "changesets", :name => "changesets_closed_at_idx"
    remove_index "changesets", :name => "changesets_created_at_idx"

    disable_extension "btree_gist"
  end
end
