class AddSearchableColumnToDiaryEntries < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      execute <<-SQL.squish
        ALTER TABLE diary_entries
        ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
          setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
          setweight(to_tsvector('simple', coalesce(body, '')), 'B')
        ) STORED;
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL.squish
        ALTER TABLE diary_entries
        DROP COLUMN IF EXISTS searchable;
      SQL
    end
  end
end
