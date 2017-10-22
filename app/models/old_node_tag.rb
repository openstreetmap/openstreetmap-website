# == Schema Information
#
# Table name: node_tags
#
#  node_id :integer          not null, primary key
#  version :integer          not null, primary key
#  k       :string           default(""), not null, primary key
#  v       :string           default(""), not null
#
# Foreign Keys
#
#  node_tags_id_fkey  (node_id => nodes.node_id)
#

class OldNodeTag < ActiveRecord::Base
  self.table_name = "node_tags"
  self.primary_keys = "node_id", "version", "k"

  belongs_to :old_node, :foreign_key => [:node_id, :version]

  validates :old_node, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => [:node_id, :version] }
end
