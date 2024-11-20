class AddImporterRole < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :user_role_enum, "importer"
  end
end
