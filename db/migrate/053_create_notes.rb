require "migrate"

class CreateNotes < ActiveRecord::Migration
  def self.up
    create_enumeration :note_status_enum, %w(open closed hidden)
    create_enumeration :note_event_enum, %w(opened closed reopened commented hidden)
  
    create_table :notes do |t|
      t.integer :latitude, :null => false
      t.integer :longitude, :null => false
      t.column :tile, :bigint, :null => false
      t.datetime :updated_at, :null => false
      t.datetime :created_at, :null => false
      t.column :status, :note_status_enum, :null => false
      t.column :closed_at, :timestamp
    end


    change_column :notes, :id, :bigint

    add_index :notes, [:tile, :status], :name => "notes_tile_idx"
    add_index :notes, [:updated_at], :name => "notes_changed_idx"
    add_index :notes, [:created_at], :name => "notess_created_idx"




   create_table :note_comments do |t|
      t.column :note_id, :bigint, :null => false
      t.boolean :visible, :null => false
      t.datetime :created_at, :null => false
      t.column :author_ip, :inet
      t.column :author_id, :bigint
      t.column :body, :text
      t.column :event, :note_event_enum
    end

    change_column :note_comments, :id, :bigint


    add_index :note_comments, [:note_id], :name => "note_comments_id_idx"

    add_foreign_key :note_comments, :notes, :column => :note_id, :name => "note_comments_note_id_fkey"
    add_foreign_key :note_comments, :users, :column => :author_id, :name => "note_comments_author_id_fkey"
    add_index :note_comments, :created_at
    add_index :note_comments, [], :columns => "to_tsvector('english', body)", :using => "GIN", :name => "index_note_comments_on_body"

  end

  def self.down
  end
end
