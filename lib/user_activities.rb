# rubocop:disable Metrics/ModuleLength
module UserActivities
  def self.for_user(user_id, limit: 5, offset: 0)
    # Get activity dates with pagination
    days = activity_days(user_id, limit, offset)
    return [] if days.empty?

    # Fetch activities for those days using ActiveRecord
    activities = []

    # Fetch changesets
    activities += Changeset.joins(:user)
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

    # Fetch diary entries
    activities += DiaryEntry.visible
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

    # Fetch changeset comments
    activities += ChangesetComment.joins(:author)
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

    # Fetch note comments
    activities += NoteComment.joins(:author)
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

    # Fetch diary comments
    activities += DiaryComment.visible
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

    # Fetch GPX files
    activities += Trace.joins(:user)
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

    # Format the results
    format_activities(activities)
  end

  def self.count_activities(user_id)
    # Use ActiveRecord for the count query
    sql = <<~SQL.squish
      SELECT COUNT(DISTINCT day)#{' '}
      FROM (
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
      ) AS activities
    SQL

    # Use bind parameters for security
    ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql([sql, { :user_id => user_id }])
    ).to_i
  end

  # Private implementation methods
  private_class_method def self.activity_days(user_id, limit, offset)
    # Use ActiveRecord with bind parameters
    sql = <<~SQL.squish
      SELECT DISTINCT day
      FROM (
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
      ) AS activities
      ORDER BY day DESC
      LIMIT :limit OFFSET :offset
    SQL

    # Use bind parameters for security
    ActiveRecord::Base.connection.select_values(
      ActiveRecord::Base.sanitize_sql([sql, { :user_id => user_id, :limit => limit, :offset => offset }])
    )
  end

  # Format the activities into the expected structure
  private_class_method def self.format_activities(activities)
    # Group by day, category, and activity_type
    grouped = activities.group_by do |activity|
      [
        activity["timestamp"].to_date,
        activity["category"],
        activity["activity_type"]
      ]
    end

    # Format into the expected structure
    result = grouped.map do |(date, category, activity_type), items|
      items_json = items.sort_by { |i| i["timestamp"] }.reverse.map do |item|
        {
          "id" => item["activity_id"],
          "reference_id" => item["reference_id"],
          "additional_reference_id" => item["additional_reference_id"],
          "description" => item["description"],
          "source_type" => item["source_type"],
          "user_display_name" => item["user_display_name"],
          "timestamp" => item["timestamp"]
        }
      end.to_json # Convert to JSON string

      # Create the key for the activity group
      key = "#{category}:#{activity_type}"

      # Create the value for the activity group
      value = {
        "count" => items.count,
        "items" => items_json
      }

      [date, key, value]
    end

    # Group by date and create the expected structure
    dates = result.group_by { |(date, _, _)| date }

    # Create the final result
    result = dates.map do |date, day_activities|
      activity_groups = {}

      # Build the activity_groups hash
      day_activities.each do |_, key, value|
        activity_groups[key] = value
      end

      {
        "activity_date" => date,
        "activity_groups" => activity_groups
      }
    end

    # Sort by date in descending order
    result.sort_by { |group| group["activity_date"] }.reverse
  end
end
# rubocop:enable Metrics/ModuleLength
