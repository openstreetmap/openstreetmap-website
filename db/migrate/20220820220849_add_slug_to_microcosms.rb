class AddSlugToMicrocosms < ActiveRecord::Migration[7.0]
  def up
    add_column :microcosms, :slug, :string
    Microcosm.update_all ["slug = key"]
  end

  def down
    Microcosm.update_all ["key = slug"]
    remove_column :microcosms, :slug
  end
end

class StrongMigrations
  class AddSlugToMicrocosms < ActiveRecord::Migration[7.0]
    disable_ddl_transaction!

    def change
      add_index :microcosms, :slug, :unique => true, :algorithm => :concurrently
    end
  end
end
