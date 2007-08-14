class UserToken < ActiveRecord::Base
  belongs_to :user

  def after_initialize
    self.token = OSM::make_token() if self.token.blank?
    self.expiry = 1.week.from_now if self.expiry.blank?
  end
end
