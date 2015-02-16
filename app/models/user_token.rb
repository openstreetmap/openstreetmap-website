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
