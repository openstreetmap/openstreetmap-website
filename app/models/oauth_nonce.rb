# Simple store of nonces. The OAuth Spec requires that any given pair of nonce and timestamps are unique.
# Thus you can use the same nonce with a different timestamp and viceversa.
class OauthNonce < ActiveRecord::Base
  validates :timestamp, :presence => true
  validates :nonce, :presence => true, :uniqueness => { :scope => :timestamp }

  # Remembers a nonce and it's associated timestamp. It returns false if it has already been used
  def self.remember(nonce, timestamp)
    return false if Time.now.to_i - timestamp.to_i > 86400
    oauth_nonce = OauthNonce.create(:nonce => nonce, :timestamp => timestamp.to_i)
    return false if oauth_nonce.new_record?
    oauth_nonce
  end
end
