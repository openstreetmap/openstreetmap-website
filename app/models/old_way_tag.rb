# == Schema Information
#
# Table name: way_tags
#
#  way_id  :integer          default(0), not null, primary key
#  k       :string           not null, primary key
#  v       :string           not null
#  version :integer          not null, primary key
#
# Foreign Keys
#
#  way_tags_id_fkey  (way_id => ways.way_id)
#

class OldWayTag < ActiveRecord::Base
  self.table_name = "way_tags"
  self.primary_keys = "way_id", "version", "k"

  belongs_to :old_way, :foreign_key => [:way_id, :version]

  validates :old_way, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :invalid_chars => true
  validates :k, :uniqueness => { :scope => [:way_id, :version] }
end
