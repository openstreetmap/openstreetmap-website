# Simple store of nonces. The OAuth Spec requires that any given pair of nonce and timestamps are unique.
# Thus you can use the same nonce with a different timestamp and viceversa.
class OauthNonce < ActiveRecord::Base
  validates_presence_of :nonce, :timestamp
  validates_uniqueness_of :nonce, :scope => :timestamp
  
  # Remembers a nonce and it's associated timestamp. It returns false if it has already been used
  def self.remember(nonce, timestamp)
    oauth_nonce = OauthNonce.create(:nonce => nonce, :timestamp => timestamp)
    return false if oauth_nonce.new_record?
    oauth_nonce
  end
end
