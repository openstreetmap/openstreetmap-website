class SetDefaultGravatarToFalseForPrivacy < ActiveRecord::Migration
  def up
    change_column :users, :image_use_gravatar, :boolean, :default => false
  end

  def down
    change_column :users, :image_use_gravatar, :boolean, :default => true
  end
end
