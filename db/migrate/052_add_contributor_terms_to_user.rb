class AddContributorTermsToUser < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :terms_agreed, :datetime
    add_column :users, :consider_pd, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :users, :consider_pd
    remove_column :users, :terms_agreed
  end
end
