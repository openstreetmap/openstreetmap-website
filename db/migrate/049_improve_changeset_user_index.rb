class ImproveChangesetUserIndex < ActiveRecord::Migration[5.0]
  def self.up
    add_index :changesets, [:user_id, :id], :name => "changesets_user_id_id_idx"
    remove_index :changesets, :name => "changesets_user_id_idx"
  end

  def self.down
    add_index :changesets, [:user_id], :name => "changesets_user_id_idx"
    remove_index :changesets, :name => "changesets_user_id_id_idx"
  end
end
