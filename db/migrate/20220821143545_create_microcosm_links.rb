class CreateMicrocosmLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :microcosm_links do |t|
      t.integer :microcosm_id, :null => false, :index => true
      t.string :site, :null => false
      t.string :url, :null => false

      t.timestamps
    end
  end
end

class CreateMicrocosmLinksFk < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :microcosm_links, :microcosm, :validate => false
  end
end

class ValidateMicrocosmLinksFk < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :microcosm_links, :microcosm
  end
end
