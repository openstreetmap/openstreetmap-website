# rubocop:disable Metrics/ModuleLength
module UserActivities
  def self.for_user(user_id, limit: 5, offset: 0)
    # Get activity dates with pagination
    days = activity_days(user_id, limit, offset)
    return [] if days.empty?

    # Fetch activities for those days
    activities = fetch_activities(user_id, days)

    # Format the results
    format_activities(activities)
  end

  def self.count_activities(user_id)
    # Use ActiveRecord's count_by_sql with parameter binding
    sql = activity_days_sql(user_id)
    ActiveRecord::Base.count_by_sql(
      ["SELECT COUNT(DISTINCT day) FROM (#{sql}) AS activities", { :user_id => user_id }]
    )
  end

  # Private implementation methods
  private_class_method def self.activity_days(user_id, limit, offset)
    sql = activity_days_sql(user_id)
    sql += " ORDER BY day DESC LIMIT :limit OFFSET :offset"

    # Use bind parameters for security
    ActiveRecord::Base.connection.select_values(
      ActiveRecord::Base.sanitize_sql([sql, { :user_id => user_id, :limit => limit, :offset => offset }])
    )
  end

  # Common SQL for activity days
  private_class_method def self.activity_days_sql(_user_id)
    <<~SQL.squish
      SELECT DATE_TRUNC('day', changesets.created_at) AS day FROM changesets WHERE user_id = :user_id
      UNION ALL
      SELECT DATE_TRUNC('day', diary_entries.created_at) AS day FROM diary_entries WHERE user_id = :user_id AND visible = true
      UNION ALL
      SELECT DATE_TRUNC('day', changeset_comments.created_at) AS day FROM changeset_comments WHERE author_id = :user_id
      UNION ALL
      SELECT DATE_TRUNC('day', note_comments.created_at) AS day FROM note_comments WHERE author_id = :user_id
      UNION ALL
      SELECT DATE_TRUNC('day', diary_comments.created_at) AS day FROM diary_comments WHERE user_id = :user_id AND visible = true
      UNION ALL
      SELECT DATE_TRUNC('day', gpx_files.timestamp) AS day FROM gpx_files WHERE user_id = :user_id
    SQL
  end

  # Fetch activities for specific days
  private_class_method def self.fetch_activities(user_id, days)
    [
      fetch_changesets(user_id, days),
      fetch_diary_entries(user_id, days),
      fetch_changeset_comments(user_id, days),
      fetch_note_comments(user_id, days),
      fetch_diary_comments(user_id, days),
      fetch_gpx_files(user_id, days)
    ].flatten
  end

  # Individual activity fetchers
  private_class_method def self.fetch_changesets(user_id, days)
    Changeset.joins(:user)
             .where(:user_id => user_id)
             .where("DATE_TRUNC('day', changesets.created_at) IN (?)", days)
             .select("changesets.created_at AS timestamp",
                     "'changeset' AS category",
                     "'opened' AS activity_type",
                     "changesets.id AS activity_id",
                     "changesets.id AS reference_id",
                     "NULL AS additional_reference_id",
                     "NULL AS description",
                     "'changeset' AS source_type",
                     "users.display_name AS user_display_name")
  end

  private_class_method def self.fetch_diary_entries(user_id, days)
    DiaryEntry.visible
              .joins(:user)
              .where(:user_id => user_id)
              .where("DATE_TRUNC('day', diary_entries.created_at) IN (?)", days)
              .select("diary_entries.created_at AS timestamp",
                      "'diary' AS category",
                      "'diary_entry' AS activity_type",
                      "diary_entries.id AS activity_id",
                      "diary_entries.id AS reference_id",
                      "diary_entries.title AS additional_reference_id",
                      "diary_entries.body AS description",
                      "'diary' AS source_type",
                      "users.display_name AS user_display_name")
  end

  private_class_method def self.fetch_changeset_comments(user_id, days)
    ChangesetComment.joins(:author)
                    .where(:author_id => user_id)
                    .where("DATE_TRUNC('day', changeset_comments.created_at) IN (?)", days)
                    .select("changeset_comments.created_at AS timestamp",
                            "'comment' AS category",
                            "'comment' AS activity_type",
                            "changeset_comments.id AS activity_id",
                            "changeset_comments.changeset_id AS reference_id",
                            "NULL AS additional_reference_id",
                            "changeset_comments.body AS description",
                            "'changeset' AS source_type",
                            "users.display_name AS user_display_name")
  end

  private_class_method def self.fetch_note_comments(user_id, days)
    NoteComment.joins(:author)
               .where(:author_id => user_id)
               .where("DATE_TRUNC('day', note_comments.created_at) IN (?)", days)
               .select("note_comments.created_at AS timestamp",
                       "'comment' AS category",
                       "'comment' AS activity_type",
                       "note_comments.id AS activity_id",
                       "note_comments.note_id AS reference_id",
                       "NULL AS additional_reference_id",
                       "note_comments.body AS description",
                       "'note' AS source_type",
                       "users.display_name AS user_display_name")
  end

  private_class_method def self.fetch_diary_comments(user_id, days)
    DiaryComment.visible
                .joins(:user)
                .joins(:diary_entry)
                .where(:user_id => user_id)
                .where("DATE_TRUNC('day', diary_comments.created_at) IN (?)", days)
                .select("diary_comments.created_at AS timestamp",
                        "'comment' AS category",
                        "'comment' AS activity_type",
                        "diary_comments.id AS activity_id",
                        "diary_comments.diary_entry_id AS reference_id",
                        "diary_entries.title AS additional_reference_id",
                        "diary_comments.body AS description",
                        "'diary' AS source_type",
                        "users.display_name AS user_display_name")
  end

  private_class_method def self.fetch_gpx_files(user_id, days)
    Trace.joins(:user)
         .where(:user_id => user_id)
         .where("DATE_TRUNC('day', gpx_files.timestamp) IN (?)", days)
         .select("gpx_files.timestamp AS timestamp",
                 "'gpx' AS category",
                 "'upload' AS activity_type",
                 "gpx_files.id AS activity_id",
                 "gpx_files.id AS reference_id",
                 "gpx_files.name AS additional_reference_id",
                 "gpx_files.description AS description",
                 "'gpx' AS source_type",
                 "users.display_name AS user_display_name")
  end

  # Format the activities into the expected structure
  private_class_method def self.format_activities(activities)
    # Group by day first
    by_day = activities.group_by { |activity| activity["timestamp"].to_date }

    # For each day, create a day object with activities grouped by category and type
    days = by_day.map do |date, day_activities|
      {
        "activity_date" => date,
        "daily_activities" => format_daily_activities(day_activities)
      }
    end

    # Sort by date in descending order
    days.sort_by { |day| day["activity_date"] }.reverse
  end

  # Format activities for a single day
  private_class_method def self.format_daily_activities(day_activities)
    day_activities.group_by { |a| [a["category"], a["activity_type"]] }
                  .map do |(category, activity_type), items|
                    {
                      "category" => category,
                      "activity_type" => activity_type,
                      "count" => items.size,
                      "items" => format_items(items)
                    }
                  end.to_json
  end

  # Format individual activity items
  private_class_method def self.format_items(items)
    items.sort_by { |i| i["timestamp"] }.reverse.map do |item|
      {
        "id" => item["activity_id"],
        "reference_id" => item["reference_id"],
        "additional_reference_id" => item["additional_reference_id"],
        "description" => item["description"],
        "source_type" => item["source_type"],
        "user_display_name" => item["user_display_name"],
        "timestamp" => item["timestamp"]
      }
    end.to_json
  end
end
# rubocop:enable Metrics/ModuleLength
