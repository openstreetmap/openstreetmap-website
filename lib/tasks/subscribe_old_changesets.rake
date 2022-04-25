namespace :db do
  task :subscribe_old_changesets => :environment do
    Changeset.find_each do |changeset|
      changeset.subscribers << changeset.user unless changeset.subscribers.exists?(changeset.user.id)
    end
  end
end
