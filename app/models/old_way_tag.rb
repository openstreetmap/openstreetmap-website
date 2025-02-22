# == Schema Information
#
# Table name: way_tags
#
#  way_id  :bigint           not null, primary key
#  k       :string           not null, primary key
#  v       :string           not null
#  version :bigint           not null, primary key
#
# Foreign Keys
#
#  way_tags_id_fkey  ([way_id, version] => ways[way_id, version])
#

class OldWayTag < ApplicationRecord
  self.table_name = "way_tags"

  belongs_to :old_way, :foreign_key => [:way_id, :version], :inverse_of => :old_tags

  validates :old_way, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => [:way_id, :version] }
end
