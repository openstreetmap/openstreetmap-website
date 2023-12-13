class AddCanonicalUserIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :users, "LOWER(NORMALIZE(display_name, NFKC))", :name => "users_display_name_canonical_idx", :algorithm => :concurrently
  end
end
