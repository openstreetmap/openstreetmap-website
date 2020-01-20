#
# Al of this junk will be reduced when I collapse the microcosm migrations.
#

class AddSlugToMicrocosms < ActiveRecord::Migration[5.2]
  def up
    add_column :microcosms, :slug, :string
    Microcosm.update_all ["slug = key"]
    #change_column_null :microcosms, :slug, false
    safety_assured do
      execute 'ALTER TABLE "microcosms" ADD CONSTRAINT "microcosms_slug_null" CHECK ("slug" is NOT NULL) NOT VALID'
    end
  end

  def down
    Microcosm.update_all ["key = slug"]
    remove_column :microcosms, :slug
  end
end

class ValidateAddSlugToMicrocosms < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      execute 'ALTER TABLE "microcosms" VALIDATE CONSTRAINT "microcosms_slug_null"'
    end
  end
end

class AddIndexToMicrocosmSlug < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :microcosms, :slug, :unique => true, :algorithm => :concurrently
  end
end
