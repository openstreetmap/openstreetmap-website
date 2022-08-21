class CreateMicrocosmLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :microcosm_links do |t|
      t.references :microcosm, :null => false, :foreign_key => true, :index => true
      t.string :site, :null => false
      t.string :url, :null => false

      t.timestamps
    end
  end
end
