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

class OauthToken < ActiveRecord::Base
  belongs_to :client_application
  belongs_to :user

  scope :authorized, -> { where("authorized_at IS NOT NULL and invalidated_at IS NULL") }

  validates :token, :presence => true, :uniqueness => true
  validates :user, :associated => true
  validates :client_application, :presence => true

  before_validation :generate_keys, :on => :create

  def invalidated?
    invalidated_at != nil
  end

  def invalidate!
    update(:invalidated_at => Time.now)
  end

  def authorized?
    !authorized_at.nil? && !invalidated?
  end

  def to_query
    "oauth_token=#{token}&oauth_token_secret=#{secret}"
  end

  protected

  def generate_keys
    self.token = OAuth::Helper.generate_key(40)[0, 40]
    self.secret = OAuth::Helper.generate_key(40)[0, 40]
  end
end
