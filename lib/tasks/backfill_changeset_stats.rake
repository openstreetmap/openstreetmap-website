# rubocop:disable Metrics/BlockLength
namespace :db do
  desc "Backfill enhanced changeset stats"
  task :changeset_stats => :environment do
    chunk_size = ENV["CHUNK_SIZE"]&.to_i || 10_000

    min_id = ENV["MIN_CHANGESET"]&.to_i || Changeset.minimum(:id)
    max_id = ENV["MAX_CHANGESET"]&.to_i || Changeset.maximum(:id)

    puts "Backfilling enhanced changeset stats from id #{min_id} to #{max_id} in chunks of #{chunk_size}"

    Changeset.where(:id => min_id..max_id)
             .where('(num_created_nodes + num_modified_nodes + num_deleted_nodes +
                      num_created_ways + num_modified_ways + num_deleted_ways +
                      num_created_relations + num_modified_relations + num_deleted_relations)
                     != num_changes')
             .in_batches(:of => chunk_size) do |batch|
      ids = batch.ids
      print "Processing changesets #{ids.first} to #{ids.last} ..."

      id_list = "{#{ids.join(',')}}"

      # Backfill enhanced changeset stats
      sql = <<~SQL.squish
        WITH total AS (
          SELECT changeset_id,
                SUM(num_created_nodes) AS num_created_nodes,
                SUM(num_modified_nodes) AS num_modified_nodes,
                SUM(num_deleted_nodes) AS num_deleted_nodes,
                SUM(num_created_ways) AS num_created_ways,
                SUM(num_modified_ways) AS num_modified_ways,
                SUM(num_deleted_ways) AS num_deleted_ways,
                SUM(num_created_relations) AS num_created_relations,
                SUM(num_modified_relations) AS num_modified_relations,
                SUM(num_deleted_relations) AS num_deleted_relations
          FROM (
              SELECT changeset_id,
                    COUNT(CASE WHEN version = 1 THEN 1 END) AS num_created_nodes,
                    COUNT(CASE WHEN version > 1 AND visible THEN 1 END) AS num_modified_nodes,
                    COUNT(CASE WHEN version > 1 AND NOT visible THEN 1 END) AS num_deleted_nodes,
                    0 AS num_created_ways,
                    0 AS num_modified_ways,
                    0 AS num_deleted_ways,
                    0 AS num_created_relations,
                    0 AS num_modified_relations,
                    0 AS num_deleted_relations
              FROM nodes
              WHERE changeset_id = ANY($1::bigint[])
              GROUP BY changeset_id

            UNION ALL

              SELECT changeset_id,
                    0 AS num_created_nodes,
                    0 AS num_modified_nodes,
                    0 AS num_deleted_nodes,
                    COUNT(CASE WHEN version = 1 THEN 1 END) AS num_created_ways,
                    COUNT(CASE WHEN version > 1 AND visible THEN 1 END) AS num_modified_ways,
                    COUNT(CASE WHEN version > 1 AND NOT visible THEN 1 END) AS num_deleted_ways,
                    0 AS num_created_relations,
                    0 AS num_modified_relations,
                    0 AS num_deleted_relations
              FROM ways
              WHERE changeset_id = ANY($1::bigint[])
              GROUP BY changeset_id

            UNION ALL

              SELECT changeset_id,
                    0 AS num_created_nodes,
                    0 AS num_modified_nodes,
                    0 AS num_deleted_nodes,
                    0 AS num_created_ways,
                    0 AS num_modified_ways,
                    0 AS num_deleted_ways,
                    COUNT(CASE WHEN version = 1 THEN 1 END) AS num_created_relations,
                    COUNT(CASE WHEN version > 1 AND visible THEN 1 END) AS num_modified_relations,
                    COUNT(CASE WHEN version > 1 AND NOT visible THEN 1 END) AS num_deleted_relations
              FROM relations
              WHERE changeset_id = ANY($1::bigint[])
              GROUP BY changeset_id
          ) AS all_stats
          GROUP BY changeset_id
        )
        UPDATE changesets
        SET num_created_nodes      = a.num_created_nodes,
            num_modified_nodes     = a.num_modified_nodes,
            num_deleted_nodes      = a.num_deleted_nodes,
            num_created_ways       = a.num_created_ways,
            num_modified_ways      = a.num_modified_ways,
            num_deleted_ways       = a.num_deleted_ways,
            num_created_relations  = a.num_created_relations,
            num_modified_relations = a.num_modified_relations,
            num_deleted_relations  = a.num_deleted_relations
        FROM total a
        WHERE changesets.id = a.changeset_id;
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "ids",
          id_list,
          ActiveRecord::Type::String.new
        )
      ]
      rows_affected = ActiveRecord::Base.connection.exec_update(sql, "UpdateStats", binds)
      puts " #{rows_affected} changesets updated."
    end

    puts "\nDone."
  end
end
# rubocop:enable Metrics/BlockLength
