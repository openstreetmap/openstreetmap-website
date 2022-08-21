class RemoveKeyFromMicrocosms < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :microcosms, :key, :string }
  end
end
