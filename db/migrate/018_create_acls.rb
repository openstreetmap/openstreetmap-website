require 'migrate'

class CreateAcls < ActiveRecord::Migration
  def self.up
    create_table "acls", myisam_table do |t|
      t.column "id",      :integer_pk, :null => false
      t.column "address", :inet,       :null => false
      t.column "netmask", :inet,       :null => false
      t.column "k",       :string,     :null => false
      t.column "v",       :string
    end

    add_index "acls", ["k"], :name => "acls_k_idx"
  end

  def self.down
    drop_table "acls"
  end
end
