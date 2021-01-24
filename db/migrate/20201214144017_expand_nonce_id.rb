class ExpandNonceId < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      change_column :oauth_nonces, :id, :bigint
    end
  end
end
