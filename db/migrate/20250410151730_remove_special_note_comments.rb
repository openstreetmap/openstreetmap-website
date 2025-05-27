class RemoveSpecialNoteComments < ActiveRecord::Migration[8.0]
  class NoteComment < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    NoteComment.where.not(:event => "commented")
               .where(:body => [nil, ""])
               .delete_all
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
