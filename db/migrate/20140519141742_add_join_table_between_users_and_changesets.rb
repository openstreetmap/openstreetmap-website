require "migrate"

class AddJoinTableBetweenUsersAndChangesets < ActiveRecord::Migration
  def change
    create_table :changesets_subscribers, :id => false do |t|
      t.column :subscriber_id, :bigint, :null => false
      t.column :changeset_id, :bigint, :null => false
    end

    add_foreign_key :changesets_subscribers, :users, :column => :subscriber_id, :name => "changesets_subscribers_subscriber_id_fkey"
    add_foreign_key :changesets_subscribers, :changesets, :name => "changesets_subscribers_changeset_id_fkey"

    add_index :changesets_subscribers, [:subscriber_id, :changeset_id], :unique => true
    add_index :changesets_subscribers, [:changeset_id]
  end
end
