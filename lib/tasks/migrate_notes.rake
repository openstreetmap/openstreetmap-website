namespace :db do
  desc "Backfills notes-columns `body`, `author_ip` and `author_id`"
  task :migrate_notes => :environment do
    scope = Note.where(:body => nil, :author => nil, :author_ip => nil)
    total_count = scope.count
    remaining_count = total_count
    puts "A total of #{total_count} Note-records have to be migrated."

    # NB: default batch size is 1000
    scope.find_in_batches do |batch|
      puts "Processing batch of #{batch.size} records."
      batch.each do |record|
        opened_comment = record.comments.unscope(:where => :visible).find_by(:event => "opened")
        (putc "x" && next) unless opened_comment

        attributes = opened_comment.attributes.slice(*%w[body author_id author_ip]).compact_blank
        record.update_columns(attributes) # rubocop:disable Rails/SkipsModelValidations
        putc "."
      end
      remaining_count -= batch.size
      puts "\nBatch completed. #{remaining_count} to go."
    end
  end
end
