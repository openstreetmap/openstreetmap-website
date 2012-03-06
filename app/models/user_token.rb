class UserToken < ActiveRecord::Base
  belongs_to :user

  attr_accessible :referer

  after_initialize :set_defaults

private

  def set_defaults
    self.token = OSM::make_token() if self.token.blank?
    self.expiry = 1.week.from_now if self.expiry.blank?
  end
end
