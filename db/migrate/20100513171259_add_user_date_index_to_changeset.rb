# encoding: utf-8

class AddUserDateIndexToChangeset < ActiveRecord::Migration
  def self.up
    add_index :changesets, [:user_id, :created_at], :name => "changesets_user_id_created_at_idx"
  end

  def self.down
    remove_index :changesets, :name => "changesets_user_id_created_at_idx"
  end
end
