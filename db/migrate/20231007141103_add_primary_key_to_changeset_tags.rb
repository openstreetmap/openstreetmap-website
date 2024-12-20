class AddPrimaryKeyToChangesetTags < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_primary_key :changeset_tags, [:changeset_id, :k], :algorithm => :concurrently
    remove_index :changeset_tags, [:changeset_id]
  end

  def down
    add_index :changeset_tags, [:changeset_id], :algorithm => :concurrently
    remove_primary_key :changeset_tags
  end
end
