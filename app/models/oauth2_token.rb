# == Schema Information
#
# Table name: oauth_tokens
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  type                  :string(20)
#  client_application_id :integer
#  token                 :string(50)
#  secret                :string(50)
#  authorized_at         :datetime
#  invalidated_at        :datetime
#  created_at            :datetime
#  updated_at            :datetime
#  allow_read_prefs      :boolean          default(FALSE), not null
#  allow_write_prefs     :boolean          default(FALSE), not null
#  allow_write_diary     :boolean          default(FALSE), not null
#  allow_write_api       :boolean          default(FALSE), not null
#  allow_read_gpx        :boolean          default(FALSE), not null
#  allow_write_gpx       :boolean          default(FALSE), not null
#  callback_url          :string
#  verifier              :string(20)
#  scope                 :string
#  valid_to              :datetime
#  allow_write_notes     :boolean          default(FALSE), not null
#
# Indexes
#
#  index_oauth_tokens_on_token    (token) UNIQUE
#  index_oauth_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  oauth_tokens_client_application_id_fkey  (client_application_id => client_applications.id)
#  oauth_tokens_user_id_fkey                (user_id => users.id)
#

class Oauth2Token < AccessToken
  attr_accessor :state

  def as_json(_options = {})
    d = { :access_token => token, :token_type => "bearer" }
    d[:expires_in] = expires_in if expires_at
    d
  end

  def to_query
    q = "access_token=#{token}&token_type=bearer"
    q << "&state=#{CGI.escape(state)}" if @state
    q << "&expires_in=#{expires_in}" if expires_at
    q << "&scope=#{CGI.escape(scope)}" if scope
    q
  end

  def expires_in
    expires_at.to_i - Time.now.to_i
  end
end
