class RemoveFacebookAndTwitterFromMicrosoms < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :microcosms, :facebook } # rubocop:disable Rails/ReversibleMigration
    safety_assured { remove_column :microcosms, :twitter } # rubocop:disable Rails/ReversibleMigration
  end
end
