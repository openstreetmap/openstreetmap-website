class OldRelationController < OldController
  private

  def lookup_old_element
    @old_element = OldRelation.find([params[:id], params[:version]])
  end

  def lookup_old_element_versions
    @elements = OldRelation.where(:relation_id => params[:id]).order(:version)
  end

  def lookup_old_elements
    ids = parse_old_elements("relations")
    @elements = OldNode.find(ids)
  end
end
