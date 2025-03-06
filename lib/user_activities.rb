# rubocop:disable Metrics/ModuleLength
module UserActivities
  def self.for_user(user_id, limit: 5, offset: 0)
    ActiveRecord::Base.connection.execute(activity_sql(user_id, :limit => limit, :offset => offset)).to_a
  end

  def self.count_activities(user_id)
    ActiveRecord::Base.connection.execute(count_sql(user_id)).first["count"]
  end

  private_class_method def self.count_sql(user_id)
    <<~SQL.squish
      WITH activities AS (
        #{base_activities_sql(user_id)}
      )
      SELECT COUNT(DISTINCT DATE_TRUNC('day', timestamp)) as count
      FROM activities
    SQL
  end

  private_class_method def self.activity_sql(user_id, limit:, offset:)
    <<~SQL.squish
      WITH activities AS (
        #{base_activities_sql(user_id)}
      ),
      activity_days AS (
        SELECT DISTINCT DATE_TRUNC('day', timestamp) as day
        FROM activities
        ORDER BY day DESC
        LIMIT #{limit}
        OFFSET #{offset}
      ),
      activities_by_day AS (
        SELECT
          DATE_TRUNC('day', a.timestamp) AS activity_date,
          a.category,
          a.activity_type,
          COUNT(*) as count,
          JSONB_AGG(
            JSONB_BUILD_OBJECT(
              'id', a.activity_id,
              'reference_id', a.reference_id,
              'additional_reference_id', a.additional_reference_id,
              'description', a.description,
              'source_type', a.source_type,
              'user_display_name', a.user_display_name,
              'timestamp', a.timestamp
            )
            ORDER BY a.timestamp DESC
          ) as items
        FROM activities a
        INNER JOIN activity_days d ON DATE_TRUNC('day', a.timestamp) = d.day
        GROUP BY activity_date, a.category, a.activity_type
      ),
      grouped_activities AS (
        SELECT
          activity_date,
          JSONB_OBJECT_AGG(
            CONCAT(category, ':', activity_type),
            JSONB_BUILD_OBJECT(
              'count', count,
              'items', items
            )
          ) as activity_groups
        FROM activities_by_day
        GROUP BY activity_date
        ORDER BY activity_date DESC
      )
      SELECT * FROM grouped_activities
    SQL
  end

  # Extract common activity types
  private_class_method def self.base_activities_sql(user_id)
    quoted_user_id = ActiveRecord::Base.connection.quote(user_id)
    [
      changeset_sql(quoted_user_id),
      diary_entry_sql(quoted_user_id),
      changeset_comment_sql(quoted_user_id),
      note_comment_sql(quoted_user_id),
      diary_comment_sql(quoted_user_id),
      gpx_file_sql(quoted_user_id)
    ].join(" UNION ALL ")
  end

  private_class_method def self.changeset_sql(quoted_user_id)
    <<~SQL.squish
      SELECT
        c.created_at AS timestamp,
        CAST('changeset' AS text) AS category,
        CAST('opened' AS text) AS activity_type,
        c.id AS activity_id,
        c.id AS reference_id,
        NULL AS additional_reference_id,
        NULL AS description,
        'changeset' AS source_type,
        NULL AS user_display_name
      FROM changesets c
      WHERE c.user_id = #{quoted_user_id}
    SQL
  end

  private_class_method def self.diary_entry_sql(quoted_user_id)
    <<~SQL.squish
      SELECT
        d.created_at AS timestamp,
        CAST('diary' AS text) AS category,
        CAST('diary_entry' AS text) AS activity_type,
        d.id AS activity_id,
        d.id AS reference_id,
        d.title AS additional_reference_id,
        d.body AS description,
        'diary' AS source_type,
        u.display_name AS user_display_name
      FROM diary_entries d
      JOIN users u ON u.id = #{quoted_user_id}
      WHERE d.user_id = #{quoted_user_id}
      AND d.visible = true
    SQL
  end

  private_class_method def self.changeset_comment_sql(quoted_user_id)
    <<~SQL.squish
      SELECT
        cc.created_at,
        CAST('comment' AS text) AS category,
        CAST('comment' AS text) AS activity_type,
        cc.id,
        cc.changeset_id AS reference_id,
        NULL AS additional_reference_id,
        cc.body,
        'changeset' AS source_type,
        NULL AS user_display_name
      FROM changeset_comments cc
      WHERE cc.author_id = #{quoted_user_id}
    SQL
  end

  private_class_method def self.note_comment_sql(quoted_user_id)
    <<~SQL.squish
      SELECT
        nc.created_at,
        CAST('comment' AS text) AS category,
        CAST('comment' AS text) AS activity_type,
        nc.id,
        nc.note_id AS reference_id,
        NULL AS additional_reference_id,
        nc.body,
        'note' AS source_type,
        NULL AS user_display_name
      FROM note_comments nc
      WHERE nc.author_id = #{quoted_user_id}
    SQL
  end

  private_class_method def self.diary_comment_sql(quoted_user_id)
    <<~SQL.squish
      SELECT
        dc.created_at,
        CAST('comment' AS text) AS category,
        CAST('comment' AS text) AS activity_type,
        dc.id,
        dc.diary_entry_id AS reference_id,
        d.title AS additional_reference_id,
        dc.body,
        'diary' AS source_type,
        u.display_name AS user_display_name
      FROM diary_comments dc
      JOIN diary_entries d ON d.id = dc.diary_entry_id
      JOIN users u ON u.id = #{quoted_user_id}
      WHERE dc.user_id = #{quoted_user_id}
      AND dc.visible = true
    SQL
  end

  private_class_method def self.gpx_file_sql(quoted_user_id)
    <<~SQL.squish
      SELECT
        g.timestamp AS timestamp,
        CAST('gpx' AS text) AS category,
        CAST('upload' AS text) AS activity_type,
        g.id AS activity_id,
        g.id AS reference_id,
        g.name AS additional_reference_id,
        g.description AS description,
        'gpx' AS source_type,
        u.display_name AS user_display_name
      FROM gpx_files g
      JOIN users u ON u.id = #{quoted_user_id}
      WHERE g.user_id = #{quoted_user_id}
    SQL
  end
end
# rubocop:enable Metrics/ModuleLength
