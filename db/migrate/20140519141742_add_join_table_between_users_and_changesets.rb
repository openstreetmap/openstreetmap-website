require 'migrate'
class AddJoinTableBetweenUsersAndChangesets < ActiveRecord::Migration
  def change
    create_table :changesets_subscribers, id: false do |t|
      t.column :subscriber_id, :bigint, null: false
      t.column :changeset_id, :bigint, null: false
    end
    add_foreign_key :changesets_subscribers, [:subscriber_id], :users, [:id]
    add_foreign_key :changesets_subscribers, [:changeset_id], :changesets, [:id]
  end
end
