class AddImporterRole < ActiveRecord::Migration[7.1]
  def up
    add_enumeration_value :user_role_enum, "importer"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
