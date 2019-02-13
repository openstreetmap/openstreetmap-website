# == Schema Information
#
# Table name: third_party_services
#
#  id         :bigint(8)        not null, primary key
#  user_ref   :bigint(8)
#  uri        :string
#  access_key :string
#
# Foreign Keys
#
#  fk_rails_...  (user_ref => users.id)
#

class ThirdPartyService < ActiveRecord::Base
  self.table_name = "third_party_services"

  has_many :third_party_keys

  validates :uri, :uniqueness => true
end
