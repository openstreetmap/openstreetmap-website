class RemoveKeyFromMicrosoms < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :microcosms, :key } # rubocop:disable Rails/ReversibleMigration
  end
end
