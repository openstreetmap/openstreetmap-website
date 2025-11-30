# frozen_string_literal: true

class CreateSpammyPhrases < ActiveRecord::Migration[8.0]
  def change
    create_table :spammy_phrases do |t|
      t.string :phrase
      t.timestamps
    end
  end
end
