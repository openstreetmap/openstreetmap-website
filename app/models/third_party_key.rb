# == Schema Information
#
# Table name: third_party_keys
#
#  id                     :bigint(8)        not null, primary key
#  third_party_service_id :bigint(8)
#  user_ref               :bigint(8)
#  data                   :string
#  created_ref            :bigint(8)
#  revoked_ref            :bigint(8)
#
# Indexes
#
#  index_third_party_keys_on_third_party_service_id  (third_party_service_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_ref => third_party_key_events.id)
#  fk_rails_...  (revoked_ref => third_party_key_events.id)
#  fk_rails_...  (third_party_service_id => third_party_services.id)
#  fk_rails_...  (user_ref => users.id)
#

class ThirdPartyKey < ActiveRecord::Base
  belongs_to :third_party_service

  def to_xml_for_retrieve
    if revoked_ref
      el = XML::Node.new "revoked"
      el["key"] = data
    else
      el = XML::Node.new "apikey"
      el["key"] = data
      if created_ref
        event = ThirdPartyKeyEvent.find(created_ref)
        el["created"] = event.created_at.xmlschema
      end
    end
    el
  end
end
