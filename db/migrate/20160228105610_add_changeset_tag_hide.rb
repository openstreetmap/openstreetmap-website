class AddChangesetTagHide < ActiveRecord::Migration
  def change
    add_column :changesets, :tags_hidden, :boolean, :default => false
  end
end
