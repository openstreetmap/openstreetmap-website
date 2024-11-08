class BackfillNoteSubscriptions < ActiveRecord::Migration[7.2]
  class NoteComment < ApplicationRecord; end
  class NoteSubscription < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    attrs = %w[user_id note_id]

    NoteComment.in_batches(:of => 1000) do |note_comments|
      rows = note_comments.distinct.where.not(:author_id => nil).pluck(:author_id, :note_id)
      NoteSubscription.upsert_all(rows.map { |r| attrs.zip(r).to_h })
    end
  end
end
