require 'migrate'

class CreateChangesetComments < ActiveRecord::Migration
  def change
    create_table :changeset_comments do |t|
      t.column :changeset_id, :bigint, :null => false
      t.column :author_id, :bigint, :null =>  false
      t.text :body, :null => false
      t.timestamp :created_at, :null => false
      t.boolean :visible, :null => false
    end

    add_foreign_key :changeset_comments, [:changeset_id], :changesets, [:id]
    add_foreign_key :changeset_comments, [:author_id], :users, [:id]

    add_index :changeset_comments, :created_at
  end
end
