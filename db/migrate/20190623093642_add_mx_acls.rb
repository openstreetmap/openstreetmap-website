class AddMxAcls < ActiveRecord::Migration[5.2]
  def change
    add_column :acls, :mx, :string

    safety_assured do
      add_index :acls, :mx
    end
  end
end
