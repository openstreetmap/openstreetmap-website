class CreateCommunityMember < ActiveRecord::Migration[7.0]
  def change
    create_table :community_members do |t|
      t.references :community, :foreign_key => true, :null => false, :index => true
      t.references :user, :foreign_key => true, :null => false, :index => true
      t.string :role, :null => false, :limit => 64

      t.timestamps
      t.index [:community_id, :user_id, :role], :unique => true
    end
  end
end
