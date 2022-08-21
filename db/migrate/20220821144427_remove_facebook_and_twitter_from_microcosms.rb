class RemoveFacebookAndTwitterFromMicrocosms < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :microcosms, :facebook, :string }
    safety_assured { remove_column :microcosms, :twitter, :string }
  end
end
