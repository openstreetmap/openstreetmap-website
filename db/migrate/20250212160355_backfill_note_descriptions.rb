class BackfillNoteDescriptions < ActiveRecord::Migration[7.2]
  class Note < ApplicationRecord; end
  class NoteComment < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    @processed_count = 0
    @failed_notes = []
    @start_time = Time.current

    # Log the start of the migration with timing details
    say_with_time "Starting note description backfill..." do
      Note.in_batches(:of => 1000) do |batch|
        process_batch(batch)
        log_progress
      end

      log_final_summary
      handle_failed_notes if @failed_notes.any?
    end
  end

  private

  def process_batch(notes)
    note_ids = notes.pluck(:id)
    comments = fetch_comments(note_ids)

    begin
      process_notes_batch(notes, comments)
    rescue StandardError => e
      # Capture and log any errors that occur while processing a batch
      handle_batch_error(note_ids, e)
    end
  end

  def fetch_comments(note_ids)
    # Fetch all relevant comments grouped by note_id for efficient access
    NoteComment
      .where(:note_id => note_ids, :event => "opened")
      .select(:note_id, :body, :author_ip, :author_id)
      .order(:created_at)
      .group_by(&:note_id)
  end

  def process_notes_batch(notes, comments)
    values = notes.filter_map do |note|
      next unless comments[note.id]&.first

      first_comment = comments[note.id].first
      generate_value_entry(note, first_comment)
    rescue StandardError => e
      # Add the note to the failed list if an error occurs
      @failed_notes << { :note_id => note.id, :error => e.message }
      nil
    end

    return if values.empty?

    execute_batch_update(values)
    @processed_count += values.size
  end

  def generate_value_entry(note, comment)
    # Convert all values to strings and properly handle NULL values
    description = ActiveRecord::Base.connection.quote(comment.body.to_s)
    user_ip = ActiveRecord::Base.connection.quote(comment.author_ip.to_s)
    user_id = comment.author_id.nil? ? "NULL" : comment.author_id

    "(#{note.id}, #{description}, #{user_ip}, #{user_id})"
  rescue StandardError => e
    # Raise a specific error for easier debugging during the migration
    raise StandardError, "Failed to generate value entry for note #{note.id}: #{e.message}"
  end

  def execute_batch_update(values)
    sql = <<-SQL.squish
      UPDATE notes
      SET description = CASE WHEN data.description = '' THEN notes.description ELSE data.description END,
          user_ip = CASE WHEN data.user_ip = '' THEN notes.user_ip ELSE data.user_ip::inet END,
          user_id = CASE WHEN data.user_id IS NULL THEN notes.user_id ELSE data.user_id::bigint END
      FROM (VALUES #{values.join(', ')}) AS data(id, description, user_ip, user_id)
      WHERE notes.id = data.id;
    SQL

    # Execute the batch SQL update
    ActiveRecord::Base.connection.execute(sql)
  rescue StandardError => e
    raise StandardError, "Failed to execute batch update: #{e.message}"
  end

  def handle_batch_error(note_ids, error)
    say "Error processing batch with IDs #{note_ids.first}-#{note_ids.last}: #{error.message}"
    @failed_notes.concat(note_ids.map { |id| { :note_id => id, :error => error.message } })
  end

  def log_progress
    return unless (@processed_count % 5000).zero?

    # Log periodic progress updates to monitor the migration
    elapsed = Time.current - @start_time
    rate = @processed_count / elapsed

    say "Processed #{@processed_count} notes in #{elapsed.round(2)}s (#{rate.round(2)} notes/s)"
    say "Failed notes so far: #{@failed_notes.size}"
  end

  def log_final_summary
    # Log the final summary of the migration, including totals and timing
    elapsed = Time.current - @start_time
    say "Migration completed in #{elapsed.round(2)}s"
    say "Total processed: #{@processed_count}"
    say "Total failed: #{@failed_notes.size}"
  end

  def handle_failed_notes
    return if @failed_notes.empty?

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = Rails.root.join("log", "failed_note_migrations_#{timestamp}.log")

    # Write failed notes and their errors to a log file for debugging
    File.open(filename, "w") do |file|
      file.puts "Failed notes from migration run at #{timestamp}"
      file.puts "Total failed notes: #{@failed_notes.size}"
      file.puts "\nDetailed errors:"

      @failed_notes.each do |failed_note|
        file.puts "Note ID: #{failed_note[:note_id]} - Error: #{failed_note[:error]}"
      end
    end

    say "Failed notes have been logged to: #{filename}"

    # Retry failed notes individually if the total is small
    retry_failed_notes if @failed_notes.size <= 1000
  end

  def retry_failed_notes
    say "Attempting to retry failed notes individually..."

    @failed_notes.each do |failed_note|
      note = Note.find(failed_note[:note_id])
      comment = NoteComment.find_by(:note_id => note.id, :event => "opened")

      next unless comment

      # Convert IPAddr to string for the update
      ip_address = comment.author_ip.respond_to?(:to_s) ? comment.author_ip.to_s : comment.author_ip

      note.update!(
        :description => comment.body,
        :user_ip => ip_address,
        :user_id => comment.author_id
      )

      say "Successfully retried note #{failed_note[:note_id]}"
    rescue StandardError => e
      # Log retry failures for debugging
      say "Retry failed for note #{failed_note[:note_id]}: #{e.message}"
    end
  end

  def down
    # Raise an error for irreversible migrations to prevent accidental rollback
    raise ActiveRecord::IrreversibleMigration
  end
end
