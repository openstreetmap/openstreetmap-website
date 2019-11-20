class RemoveNearbyFromUsers < ActiveRecord::Migration[5.2]
  def change
    # We've already ignored this column in the model, so it is safe to remove
    safety_assured { remove_column :users, :nearby, :integer, :default => 50 }
  end
end
