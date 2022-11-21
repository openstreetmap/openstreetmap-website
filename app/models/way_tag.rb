# == Schema Information
#
# Table name: current_way_tags
#
#  way_id :bigint(8)        not null, primary key
#  k      :string           default(""), not null, primary key
#  v      :string           default(""), not null
#
# Foreign Keys
#
#  current_way_tags_id_fkey  (way_id => current_ways.id)
#

class WayTag < ApplicationRecord
  self.table_name = "current_way_tags"
  self.primary_keys = "way_id", "k"

  belongs_to :way

  validates :way, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => :way_id }
end
