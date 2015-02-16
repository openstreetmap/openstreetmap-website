class OldNodeController < OldController
  private

  def lookup_old_element
    @old_element = OldNode.find([params[:id], params[:version]])
  end

  def lookup_old_element_versions
    @elements = OldNode.where(:node_id => params[:id]).order(:version)
  end
end
