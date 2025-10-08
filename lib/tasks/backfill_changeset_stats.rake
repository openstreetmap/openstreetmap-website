# frozen_string_literal: true

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
        WITH changes AS (
            SELECT
              nodes.changeset_id,
              CASE WHEN nodes.version = 1 THEN 1 ELSE 0 END AS num_created_nodes,
              CASE WHEN nodes.version > 1 AND nodes.visible THEN 1 ELSE 0 END AS num_modified_nodes,
              CASE WHEN nodes.version > 1 AND NOT nodes.visible THEN 1 ELSE 0 END AS num_deleted_nodes,
              0 AS num_created_ways,
              0 AS num_modified_ways,
              0 AS num_deleted_ways,
              0 AS num_created_relations,
              0 AS num_modified_relations,
              0 AS num_deleted_relations
            FROM nodes
            WHERE nodes.changeset_id = ANY($1::bigint[])
          UNION ALL
            SELECT
              ways.changeset_id,
              0 AS num_created_nodes,
              0 AS num_modified_nodes,
              0 AS num_deleted_nodes,
              CASE WHEN ways.version = 1 THEN 1 ELSE 0 END AS num_created_ways,
              CASE WHEN ways.version > 1 AND ways.visible THEN 1 ELSE 0 END AS num_modified_ways,
              CASE WHEN ways.version > 1 AND NOT ways.visible THEN 1 ELSE 0 END AS num_deleted_ways,
              0 AS num_created_relations,
              0 AS num_modified_relations,
              0 AS num_deleted_relations
            FROM ways
            WHERE ways.changeset_id = ANY($1::bigint[])
          UNION ALL
            SELECT
              relations.changeset_id,
              0 AS num_created_nodes,
              0 AS num_modified_nodes,
              0 AS num_deleted_nodes,
              0 AS num_created_ways,
              0 AS num_modified_ways,
              0 AS num_deleted_ways,
              CASE WHEN relations.version = 1 THEN 1 ELSE 0 END AS num_created_relations,
              CASE WHEN relations.version > 1 AND relations.visible THEN 1 ELSE 0 END AS num_modified_relations,
              CASE WHEN relations.version > 1 AND NOT relations.visible THEN 1 ELSE 0 END AS num_deleted_relations
            FROM relations
            WHERE relations.changeset_id = ANY($1::bigint[])
        ),
        total AS (
          SELECT
            changes.changeset_id,
            SUM(changes.num_created_nodes) AS num_created_nodes,
            SUM(changes.num_modified_nodes) AS num_modified_nodes,
            SUM(changes.num_deleted_nodes) AS num_deleted_nodes,
            SUM(changes.num_created_ways) AS num_created_ways,
            SUM(changes.num_modified_ways) AS num_modified_ways,
            SUM(changes.num_deleted_ways) AS num_deleted_ways,
            SUM(changes.num_created_relations) AS num_created_relations,
            SUM(changes.num_modified_relations) AS num_modified_relations,
            SUM(changes.num_deleted_relations) AS num_deleted_relations
          FROM changes
          GROUP BY changes.changeset_id
        )
        UPDATE changesets
        SET num_created_nodes      = total.num_created_nodes,
            num_modified_nodes     = total.num_modified_nodes,
            num_deleted_nodes      = total.num_deleted_nodes,
            num_created_ways       = total.num_created_ways,
            num_modified_ways      = total.num_modified_ways,
            num_deleted_ways       = total.num_deleted_ways,
            num_created_relations  = total.num_created_relations,
            num_modified_relations = total.num_modified_relations,
            num_deleted_relations  = total.num_deleted_relations,
            num_changes            = total.num_created_nodes +
                                     total.num_modified_nodes +
                                     total.num_deleted_nodes +
                                     total.num_created_ways +
                                     total.num_modified_ways +
                                     total.num_deleted_ways +
                                     total.num_created_relations +
                                     total.num_modified_relations +
                                     total.num_deleted_relations
        FROM total
        WHERE changesets.id = total.changeset_id
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
