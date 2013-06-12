class CreateGroup < ActiveRecord::Migration
  def up
    create_table :groups do |t|
      t.string :title
      t.text   :description
      t.text   :description_format
     end
  end

  def down
    drop_table :groups
  end
end
