namespace :db do
  desc "Expire old tokens"
  task :expire_tokens => :environment do
    OauthNonce.where("timestamp < EXTRACT(EPOCH FROM NOW() - INTERVAL '1 day')").delete_all
    OauthToken.where("invalidated_at < NOW() - INTERVAL '28 days'").delete_all
    RequestToken.where("authorized_at IS NULL AND created_at < NOW() - INTERVAL '28 days'").delete_all
    Doorkeeper::AccessGrant.where("revoked_at < NOW() - INTERVAL '28 days' OR (created_at + expires_in * INTERVAL '1 second') < NOW() - INTERVAL '28 days'").delete_all
    Doorkeeper::AccessToken.where("revoked_at < NOW() - INTERVAL '28 days' OR (created_at + expires_in * INTERVAL '1 second') < NOW() - INTERVAL '28 days'").delete_all
  end
end
