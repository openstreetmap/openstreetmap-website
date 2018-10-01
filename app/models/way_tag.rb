# == Schema Information
#
# Table name: current_way_tags
#
#  way_id :integer          not null, primary key
#  k      :string           default(""), not null, primary key
#  v      :string           default(""), not null
#
# Foreign Keys
#
#  current_way_tags_id_fkey  (way_id => current_ways.id)
#

class WayTag < ActiveRecord::Base
  self.table_name = "current_way_tags"
  self.primary_keys = "way_id", "k"

  belongs_to :way

  attr_accessor :skip_uniqueness
  validates :way, :presence => true, :associated => true, :unless => :skip_uniqueness
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => :way_id }, :unless => :skip_uniqueness
end
