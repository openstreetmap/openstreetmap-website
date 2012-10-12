class AddImageUseGravatarToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :image_use_gravatar, :boolean, :null => false, :default => false

    # For people who don't have images on osm.org, enable Gravatar.
    User.where(:image_file_name => nil).update_all(:image_use_gravatar => true)

    change_column_default :users, :image_use_gravatar, true
  end

  def self.down
    remove_column :users, :image_use_gravatar
  end
end
