# == Schema Information
#
# Table name: community_links
#
#  id           :bigint(8)        not null, primary key
#  community_id :bigint(8)        not null
#  text         :string           not null
#  url          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_community_links_on_community_id  (community_id)
#
# Foreign Keys
#
#  fk_rails_...  (community_id => communities.id)
#

class CommunityLink < ApplicationRecord
  belongs_to :community
  validates :text, :presence => true, :length => 1..255, :characters => true
  validates :url, :presence => true, :length => 1..255, :url => { :schemes => ["https"] }
end
