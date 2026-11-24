# frozen_string_literal: true

namespace :db do
  desc "Backfill gpx_tracks linestrings"
  task :gpx_tracks => :environment do
    $stdout.sync = true

    chunk_size = ENV["CHUNK_SIZE"]&.to_i || 10_000
    min_id = ENV["MIN_TRACE"]&.to_i || Trace.minimum(:id)
    max_id = ENV["MAX_TRACE"]&.to_i || Trace.maximum(:id)

    puts "Backfilling gpx_tracks from trace #{min_id} to #{max_id} in chunks of #{chunk_size}"

    # Traces that already have rows are skipped, so running a range again is cheap.
    Trace.visible.imported
         .where(:id => min_id..max_id)
         .where("NOT EXISTS (SELECT 1 FROM gpx_tracks WHERE gpx_tracks.gpx_id = gpx_files.id)")
         .in_batches(:of => chunk_size) do |batch|
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      first_id, last_id = batch.map(&:id).minmax
      traces = 0
      empty = 0
      segments = 0

      batch.each do |trace|
        inserted = TraceLinestringJob.perform_now(trace)
        traces += 1
        segments += inserted
        empty += 1 if inserted.zero?
      rescue StandardError => e
        puts "trace #{trace.id} error=#{e.message}"
      end

      seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).round

      puts "range #{first_id}-#{last_id} ok traces=#{traces} empty=#{empty} segments=#{segments} #{seconds}s"
    end

    puts "\nDone."
  end
end
