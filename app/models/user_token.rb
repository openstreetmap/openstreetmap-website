# == Schema Information
#
# Table name: user_tokens
#
#  id      :bigint(8)        not null, primary key
#  user_id :bigint(8)        not null
#  token   :string           not null
#  expiry  :datetime         not null
#  referer :text
#
# Indexes
#
#  user_tokens_token_idx    (token) UNIQUE
#  user_tokens_user_id_idx  (user_id)
#
# Foreign Keys
#
#  user_tokens_user_id_fkey  (user_id => users.id)
#

class UserToken < ActiveRecord::Base
  belongs_to :user

  after_initialize :set_defaults

  def expired?
    expiry < Time.now
  end

  private

  def set_defaults
    self.token = OSM.make_token if token.blank?
    self.expiry = 1.week.from_now if expiry.blank?
  end
end
