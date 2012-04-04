class OldRelationController < OldController

  private
  
  def lookup_old_element
    @old_element = OldRelation.find([params[:id], params[:version]])
  end

  def lookup_old_elements_via_current
    relation = Relation.find(params[:id])
    @elements = relation.old_relations
  end
end
