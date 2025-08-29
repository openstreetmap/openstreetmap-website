# frozen_string_literal: true

class CreateSocialLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :social_links do |t|
      t.references :user, :null => false, :foreign_key => true
      t.string :url, :null => false

      t.timestamps
    end
  end
end
