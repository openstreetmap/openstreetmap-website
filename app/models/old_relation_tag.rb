# == Schema Information
#
# Table name: relation_tags
#
#  relation_id :bigint(8)        not null, primary key
#  k           :string           default(""), not null, primary key
#  v           :string           default(""), not null
#  version     :bigint(8)        not null, primary key
#
# Foreign Keys
#
#  relation_tags_id_fkey  (["relation_id", "version"] => relations.["relation_id", "version"])
#

class OldRelationTag < ApplicationRecord
  self.table_name = "relation_tags"

  belongs_to :old_relation, :query_constraints => [:relation_id, :version], :inverse_of => :old_tags

  validates :old_relation, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => [:relation_id, :version] }
end
