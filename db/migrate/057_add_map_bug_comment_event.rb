require 'migrate'

class AddMapBugCommentEvent < ActiveRecord::Migration
  def self.up
    create_enumeration :map_bug_event_enum, ["opened", "closed", "reopened", "commented", "hidden"]

    add_column :map_bug_comment, :event, :map_bug_event_enum
  end

  def self.down
    remove_column :map_bug_comment, :event

    drop_enumeration :map_bug_event_enum
  end
end
