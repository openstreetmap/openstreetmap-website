# frozen_string_literal: true

# This migration comes from noticed (originally 20231215190233)
class CreateNoticedTables < ActiveRecord::Migration[8.1]
  def change
    create_table :noticed_events do |t|
      t.string :type
      t.belongs_to :record, :polymorphic => true
      if t.respond_to?(:jsonb)
        t.jsonb :params
      else
        t.json :params
      end

      t.timestamps
    end

    create_table :noticed_notifications do |t|
      t.string :type
      t.belongs_to :event, :null => false
      t.belongs_to :recipient, :polymorphic => true, :null => false
      t.datetime :read_at
      t.datetime :seen_at

      t.timestamps
    end
  end
end
