class AddMessageSenderIndex < ActiveRecord::Migration[4.2]
  def self.up
    add_index :messages, [:from_user_id], :name => "messages_from_user_id_idx"
  end

  def self.down
    remove_index :messages, :name => "messages_from_user_id_idx"
  end
end
