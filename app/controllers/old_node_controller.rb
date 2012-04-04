class OldNodeController < OldController

  private
  
  def lookup_old_element
    @old_element = OldNode.find([params[:id], params[:version]])
  end

  def lookup_old_elements_via_current
    node = Node.find(params[:id])
    @elements = node.old_nodes
  end
end
