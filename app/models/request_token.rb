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

class RequestToken < OauthToken
  attr_accessor :provided_oauth_verifier

  def authorize!(user)
    return false if authorized?

    self.user = user
    self.authorized_at = Time.now
    self.verifier = OAuth::Helper.generate_key(20)[0, 20] unless oauth10?
    save
  end

  def exchange!
    return false unless authorized?
    return false unless oauth10? || verifier == provided_oauth_verifier

    RequestToken.transaction do
      params = { :user => user, :client_application => client_application }
      # copy the permissions from the authorised request token to the access token
      client_application.permissions.each do |p|
        params[p] = self[p]
      end

      access_token = AccessToken.create(params)
      invalidate!
      access_token
    end
  end

  def to_query
    if oauth10?
      super
    else
      "#{super}&oauth_callback_confirmed=true"
    end
  end

  def oob?
    callback_url.nil? || callback_url.casecmp("oob").zero?
  end

  def oauth10?
    Settings.key?(:oauth_10_support) && Settings.oauth_10_support && callback_url.blank?
  end
end
