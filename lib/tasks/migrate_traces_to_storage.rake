namespace :traces do
  desc "Migrate trace files to ActiveStorage"
  task :migrate_to_storage => :environment do
    Trace
      .with_attached_file
      .where(:file_attachment => { :id => nil })
      .find_each(&:migrate_to_storage!)
  end
end
