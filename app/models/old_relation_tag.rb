# == Schema Information
#
# Table name: relation_tags
#
#  relation_id :bigint(8)        default(0), not null, primary key
#  k           :string           default(""), not null, primary key
#  v           :string           default(""), not null
#  version     :bigint(8)        not null, primary key
#
# Foreign Keys
#
#  relation_tags_id_fkey  (relation_id => relations.relation_id)
#

class OldRelationTag < ActiveRecord::Base
  self.table_name = "relation_tags"
  self.primary_keys = "relation_id", "version", "k"

  belongs_to :old_relation, :foreign_key => [:relation_id, :version]

  validates :old_relation, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => [:relation_id, :version] }
end
