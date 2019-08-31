class AddAclIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :acls, :domain
    add_index :acls, :address, :using => :gist, :opclass => :inet_ops
  end
end
