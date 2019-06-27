class AddTermsSeenToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :terms_seen, :boolean, :null => false, :default => false

    # best guess available is just that everyone who has agreed has
    # seen the terms, and that noone else has.
    User.update_all "terms_seen = (terms_agreed is not null)"
  end

  def self.down
    remove_column :users, :terms_seen
  end
end
