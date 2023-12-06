class AlterSequencesBigint < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      execute "ALTER SEQUENCE oauth_nonces_id_seq AS bigint"
      execute "ALTER SEQUENCE notes_id_seq AS bigint"
      execute "ALTER SEQUENCE note_comments_id_seq AS bigint"
    end
  end

  def down
    safety_assured do
      execute "ALTER SEQUENCE oauth_nonces_id_seq AS integer"
      execute "ALTER SEQUENCE notes_id_seq AS integer"
      execute "ALTER SEQUENCE note_comments_id_seq AS integer"
    end
  end
end
