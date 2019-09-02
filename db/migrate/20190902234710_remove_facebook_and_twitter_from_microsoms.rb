class RemoveFacebookAndTwitterFromMicrosoms < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :microcosms, :facebook }
    safety_assured { remove_column :microcosms, :twitter }
  end
end
