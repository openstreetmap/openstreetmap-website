# == Schema Information
#
# Table name: microcosm_links
#
#  id           :bigint(8)        not null, primary key
#  microcosm_id :integer          not null
#  site         :string           not null
#  url          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_microcosm_links_on_microcosm_id  (microcosm_id)
#

class MicrocosmLink < ApplicationRecord
  belongs_to :microcosm
  validates :site, :presence => true, :length => 1..255, :characters => true
  validates :url, :presence => true, :length => 1..255, :url => { :schemes => ["https"] }
end
