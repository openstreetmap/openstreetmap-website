class CreateCommunityLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :community_links do |t|
      t.references :community, :null => false, :foreign_key => true, :index => true
      t.string :text, :null => false
      t.string :url, :null => false

      t.timestamps
    end
  end
end
