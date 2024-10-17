namespace :db do
  desc "Backfills notes-columns `body`, `author_ip` and `author_id`"
  task :migrate_notes => :environment do
    scope = Note.where(:body => nil)
    total_count = scope.count
    remaining_count = total_count
    puts "A total of #{total_count} Note-records have to be migrated."

    # NB: default batch size is 1000
    scope.find_in_batches do |batch|
      puts "Processing batch of #{batch.size} records."
      batch.each do |record|
        migration = Note::MigrateFirstComment.new(record)
        (putc "x" && next) if migration.skip?

        if migration.call
          putc "."
        else
          puts "\nFailed for Note(id:#{record.id})"
        end
      end
      remaining_count -= batch.size
      puts "\nBatch completed. #{remaining_count} to go."
    end
  end
end
