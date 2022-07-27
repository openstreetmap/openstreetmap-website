namespace :db do
  task :subscribe_diary_authors => :environment do
    DiaryEntry.find_each do |diary_entry|
      diary_entry.subscriptions.create(:user => diary_entry.user) unless diary_entry.subscribers.exists?(diary_entry.user.id)
    end
  end
end
