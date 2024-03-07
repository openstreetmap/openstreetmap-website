class ValidateAndModifyRedactionTitleAndDescription < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    validate_check_constraint :redactions, :name => "redaction_title_not_null"
    validate_check_constraint :redactions, :name => "redaction_description_not_null"

    change_column_null :redactions, :title, false
    change_column_null :redactions, :description, false

    remove_check_constraint :redactions, :name => "redaction_title_not_null"
    remove_check_constraint :redactions, :name => "redaction_description_not_null"
  end

  def down
    change_column_null :redactions, :title, true
    change_column_null :redactions, :description, true
  end
end
