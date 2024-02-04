class AddAuthorAndBodyToNotes < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_table :notes, :bulk => true do |t|
        t.column :author_id, :bigint, :null => true
        t.column :author_ip, :inet, :null => true
        t.column :body, :text, :null => true
      end
    end

    add_foreign_key :notes, :users, :column => :author_id, :validate => false
  end
end
