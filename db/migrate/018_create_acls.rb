class CreateAcls < ActiveRecord::Migration
  def self.up
    create_table "acls", myisam_table do |t|
      t.column "id",      :integer, :null => false
      t.column "address", :integer, :null => false
      t.column "netmask", :integer, :null => false
      t.column "k",       :string,  :null => false
      t.column "v",       :string
    end

    add_primary_key "acls", ["id"]
    add_index "acls", ["k"], :name => "acls_k_idx"

    change_column "acls", "id", :integer, :null => false, :options => "AUTO_INCREMENT"
    change_column "acls", "address", :integer, :null => false, :unsigned => true
    change_column "acls", "netmask", :integer, :null => false, :unsigned => true
  end

  def self.down
    drop_table "acls"
  end
end
