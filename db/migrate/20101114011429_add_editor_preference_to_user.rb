class AddEditorPreferenceToUser < ActiveRecord::Migration[5.0]
  def self.up
    add_column :users, :preferred_editor, :string
  end

  def self.down
    remove_column :users, :preferred_editor
  end
end
