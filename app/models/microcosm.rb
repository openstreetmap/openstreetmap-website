# == Schema Information
#
# Table name: microcosms
#
#  id          :bigint(8)        not null, primary key
#  name        :string           not null
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  slug        :string
#  location    :string           not null
#  lat         :decimal(, )      not null
#  lon         :decimal(, )      not null
#  min_lat     :integer          not null
#  max_lat     :integer          not null
#  min_lon     :integer          not null
#  max_lon     :integer          not null
#

class Microcosm < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  self.ignored_columns = ["key"]

  has_many :microcosm_members  #, :dependent => :destroy
  has_many :users, :through => :microcosm_members  # TODO: counter_cache
  has_many :microcosm_links

  def set_link(site, url)
    link = MicrocosmLink.find_or_create_by!(microcosm_id: self.id, site: site)
    link.url = url
    link.save!
  end
end
