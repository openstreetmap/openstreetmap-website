class CreateGroup < ActiveRecord::Migration
  def up
    create_table :groups do |t|
      t.string :title
      t.text   :description
     end
  end

  def down
    drop_table :groups
  end
end
