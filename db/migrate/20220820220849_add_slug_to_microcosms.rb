class AddSlugToMicrocosms < ActiveRecord::Migration[7.0]
  def up
    # This migration will be run at the same time as the migration to create
    # microcosms, so there will be no records yet.
    safety_assured do
      add_column :microcosms, :slug, :string, :null => false # rubocop:disable Rails/NotNullColumn
      add_index :microcosms, :slug, :unique => true
    end
    Microcosm.update_all ["slug = key"]
  end

  def down
    Microcosm.update_all ["key = slug"]
    remove_column :microcosms, :slug
  end
end
