# Simple store of nonces. The OAuth Spec requires that any given pair of nonce and timestamps are unique.
# Thus you can use the same nonce with a different timestamp and viceversa.
class OauthNonce < ActiveRecord::Base
  validates :timestamp, :presence => true
  validates :nonce, :presence => true, :uniqueness => { :scope => :timestamp }

  # Remembers a nonce and it's associated timestamp. It returns false if it has already been used
  def self.remember(nonce, timestamp)
    oauth_nonce = OauthNonce.create(:nonce => nonce, :timestamp => timestamp)
    return false if oauth_nonce.new_record?
    oauth_nonce
  end
end

# == Schema Information
#
# Table name: oauth_nonces
#
#  id         :integer          not null, primary key
#  nonce      :string(255)
#  timestamp  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_oauth_nonces_on_nonce_and_timestamp  (nonce,timestamp) UNIQUE
#
