# == Schema Information
#
# Table name: node_tags
#
#  node_id :bigint(8)        not null, primary key
#  version :bigint(8)        not null, primary key
#  k       :string           default(""), not null, primary key
#  v       :string           default(""), not null
#
# Foreign Keys
#
#  node_tags_id_fkey  (node_id => nodes.node_id)
#

class OldNodeTag < ApplicationRecord
  self.table_name = "node_tags"
  self.primary_keys = "node_id", "version", "k"

  belongs_to :old_node, :foreign_key => [:node_id, :version], :inverse_of => :old_tags

  validates :old_node, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => [:node_id, :version] }
end
