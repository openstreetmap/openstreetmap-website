class AddDomainToAcl < ActiveRecord::Migration[4.2]
  def up
    add_column :acls, :domain, :string
    change_column :acls, :address, :inet, :null => true
  end

  def down
    change_column :acls, :address, :inet, :null => false
    remove_column :acls, :domain
  end
end
