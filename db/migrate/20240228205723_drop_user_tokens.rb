class DropUserTokens < ActiveRecord::Migration[7.1]
  def up
    drop_table :user_tokens
  end
end
