# == Schema Information
#
# Table name: microcosm_links
#
#  id           :bigint(8)        not null, primary key
#  microcosm_id :integer
#  site         :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class MicrocosmLink < ApplicationRecord
  belongs_to :microcosm
end
