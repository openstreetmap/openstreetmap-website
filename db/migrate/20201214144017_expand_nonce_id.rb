class ExpandNonceId < ActiveRecord::Migration[6.0]
  def up
    safety_assured do
      change_column :oauth_nonces, :id, :bigint
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
