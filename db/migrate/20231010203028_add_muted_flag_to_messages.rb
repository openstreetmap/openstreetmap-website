class AddMutedFlagToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :muted, :boolean, :default => false, :null => false
  end
end
