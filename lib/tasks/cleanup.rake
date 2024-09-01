namespace :db do
  desc "Expire old tokens"
  task :expire_tokens => :environment do
    Doorkeeper::AccessGrant.where("revoked_at < NOW() - INTERVAL '28 days' OR (created_at + expires_in * INTERVAL '1 second') < NOW() - INTERVAL '28 days'").delete_all
    Doorkeeper::AccessToken.where("revoked_at < NOW() - INTERVAL '28 days' OR (created_at + expires_in * INTERVAL '1 second') < NOW() - INTERVAL '28 days'").delete_all
  end
end
