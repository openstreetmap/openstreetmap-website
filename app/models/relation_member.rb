class RelationMember < ActiveRecord::Base
  set_table_name 'current_relation_members'

  # problem with RelationMember is that it may link to any one 
  # object (a node, a way, another relation), and belongs_to is
  # not flexible enough for that. So we do this, which is ugly,
  # but fortunately rails won't actually run the SQL behind that
  # unless someone really accesses .node, .way, or
  # .relation - which is what we do below based on member_type.
  # (and no: the :condition on belongs_to doesn't work here as
  # it is a condition on the *referenced* object not the 
  # *referencing* object!)
  
  belongs_to :node, :foreign_key => "member_id"
  belongs_to :way, :foreign_key => "member_id"
  belongs_to :relation, :foreign_key => "member_id"

  # so we define this "member" function that returns whatever it
  # is.
 
  def member()
    return (member_type == "node") ? node : (member_type == "way") ? way : relation
  end

  # NOTE - relations are SUBJECTS of memberships. The fact that nodes, 
  # ways, and relations can be the OBJECT of a membership,
  # i.e. a node/way/relation can be referenced throgh a
  # RelationMember object, is NOT modelled in rails, i.e. these links
  # have to be resolved manually, on demand. 
end
