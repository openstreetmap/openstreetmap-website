class AddUseGravatarToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :use_gravatar, :boolean, :null => false, :default => false

    User.all.each do |user|
      # For people who don't have images on osm.org, enable Gravatar.
      user.use_gravatar = !user.image.file?
      user.save
    end
  end

  def self.down
    remove_column :users, :use_gravatar
  end
end
