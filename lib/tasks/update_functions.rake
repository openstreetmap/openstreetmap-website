namespace :db do
  desc "Update database function definitions"
  task :update_functions => :environment do
    ActiveRecord::Base.connection.execute DatabaseFunctions::API_RATE_LIMIT
    ActiveRecord::Base.connection.execute DatabaseFunctions::API_SIZE_LIMIT
  end
end
