module DatabaseFunctions
  API_RATE_LIMIT = %(
    CREATE OR REPLACE FUNCTION api_rate_limit(user_id int8)
      RETURNS int4
      AS $$
    DECLARE
      min_changes_per_hour int4 := #{Settings.min_changes_per_hour};
      initial_changes_per_hour int4 := #{Settings.initial_changes_per_hour};
      max_changes_per_hour int4 := #{Settings.max_changes_per_hour};
      days_to_max_changes int4 := #{Settings.days_to_max_changes};
      importer_changes_per_hour int4 := #{Settings.importer_changes_per_hour};
      moderator_changes_per_hour int4 := #{Settings.moderator_changes_per_hour};
      roles text[];
      last_block timestamp without time zone;
      first_change timestamp without time zone;
      active_reports int4;
      time_since_first_change double precision;
      max_changes double precision;
      recent_changes int4;
    BEGIN
      SELECT ARRAY_AGG(user_roles.role) INTO STRICT roles FROM user_roles WHERE user_roles.user_id = api_rate_limit.user_id;

      IF 'moderator' = ANY(roles) THEN
        max_changes := moderator_changes_per_hour;
      ELSIF 'importer' = ANY(roles) THEN
        max_changes := importer_changes_per_hour;
      ELSE
        SELECT user_blocks.created_at INTO last_block FROM user_blocks WHERE user_blocks.user_id = api_rate_limit.user_id ORDER BY user_blocks.created_at DESC LIMIT 1;

        IF FOUND THEN
          SELECT changesets.created_at INTO first_change FROM changesets WHERE changesets.user_id = api_rate_limit.user_id AND changesets.created_at > last_block ORDER BY changesets.created_at LIMIT 1;
        ELSE
          SELECT changesets.created_at INTO first_change FROM changesets WHERE changesets.user_id = api_rate_limit.user_id ORDER BY changesets.created_at LIMIT 1;
        END IF;

        IF NOT FOUND THEN
          first_change := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
        END IF;

        SELECT COUNT(*) INTO STRICT active_reports
        FROM issues INNER JOIN reports ON reports.issue_id = issues.id
        WHERE issues.reported_user_id = api_rate_limit.user_id AND issues.status = 'open' AND reports.updated_at >= COALESCE(issues.resolved_at, '1970-01-01');

        time_since_first_change := EXTRACT(EPOCH FROM CURRENT_TIMESTAMP AT TIME ZONE 'UTC' - first_change);

        max_changes := max_changes_per_hour * POWER(time_since_first_change, 2) / POWER(days_to_max_changes * 24 * 60 * 60, 2);
        max_changes := GREATEST(initial_changes_per_hour, LEAST(max_changes_per_hour, FLOOR(max_changes)));
        max_changes := max_changes / POWER(2, active_reports);
        max_changes := GREATEST(min_changes_per_hour, LEAST(max_changes_per_hour, max_changes));
      END IF;

      SELECT COALESCE(SUM(changesets.num_changes), 0) INTO STRICT recent_changes FROM changesets WHERE changesets.user_id = api_rate_limit.user_id AND changesets.created_at >= CURRENT_TIMESTAMP AT TIME ZONE 'UTC' - '1 hour'::interval;

      RETURN max_changes - recent_changes;
    END;
    $$ LANGUAGE plpgsql STABLE;
  ).freeze

  API_SIZE_LIMIT = %(
    CREATE OR REPLACE FUNCTION api_size_limit(user_id int8)
      RETURNS int8
      AS $$
    DECLARE
      min_size_limit int8 := #{Settings.min_size_limit};
      initial_size_limit int8 := #{Settings.initial_size_limit};
      max_size_limit int8 := #{Settings.max_size_limit};
      days_to_max_size_limit int4 := #{Settings.days_to_max_size_limit};
      importer_size_limit int8 := #{Settings.importer_size_limit};
      moderator_size_limit int8 := #{Settings.moderator_size_limit};
      roles text[];
      last_block timestamp without time zone;
      first_change timestamp without time zone;
      active_reports int4;
      time_since_first_change double precision;
      size_limit int8;
    BEGIN
      SELECT ARRAY_AGG(user_roles.role) INTO STRICT roles FROM user_roles WHERE user_roles.user_id = api_size_limit.user_id;

      IF 'moderator' = ANY(roles) THEN
        size_limit := moderator_size_limit;
      ELSIF 'importer' = ANY(roles) THEN
        size_limit := importer_size_limit;
      ELSE
        SELECT user_blocks.created_at INTO last_block FROM user_blocks WHERE user_blocks.user_id = api_size_limit.user_id ORDER BY user_blocks.created_at DESC LIMIT 1;

        IF FOUND THEN
          SELECT changesets.created_at INTO first_change FROM changesets WHERE changesets.user_id = api_size_limit.user_id AND changesets.created_at > last_block ORDER BY changesets.created_at LIMIT 1;
        ELSE
          SELECT changesets.created_at INTO first_change FROM changesets WHERE changesets.user_id = api_size_limit.user_id ORDER BY changesets.created_at LIMIT 1;
        END IF;

        IF NOT FOUND THEN
          first_change := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
        END IF;

        SELECT COUNT(*) INTO STRICT active_reports
        FROM issues INNER JOIN reports ON reports.issue_id = issues.id
        WHERE issues.reported_user_id = api_size_limit.user_id AND issues.status = 'open' AND reports.updated_at >= COALESCE(issues.resolved_at, '1970-01-01');

        time_since_first_change := EXTRACT(EPOCH FROM CURRENT_TIMESTAMP AT TIME ZONE 'UTC' - first_change);

        size_limit := max_size_limit * POWER(time_since_first_change, 2) / POWER(days_to_max_size_limit * 24 * 60 * 60, 2);
        size_limit := GREATEST(initial_size_limit, LEAST(max_size_limit, FLOOR(size_limit)));
        size_limit := size_limit / POWER(2, active_reports);
        size_limit := GREATEST(min_size_limit, LEAST(max_size_limit, size_limit));
      END IF;

      RETURN size_limit;
    END;
    $$ LANGUAGE plpgsql STABLE;
  ).freeze
end
