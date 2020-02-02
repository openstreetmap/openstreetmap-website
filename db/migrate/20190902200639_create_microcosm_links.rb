class CreateMicrocosmLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :microcosm_links do |t|
      t.references :microcosm, :foreign_key => true, :null => false
      t.string :site, :null => false
      t.string :url, :null => false
      t.timestamps
    end
  end
end
