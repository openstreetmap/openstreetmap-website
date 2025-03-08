module Api
  class OldNodesController < OldElementsController
    private

    def lookup_old_element
      @old_element = OldNode.find([params[:node_id], params[:version]])
    end

    def lookup_old_element_versions
      @elements = OldNode.where(:node_id => params[:node_id]).order(:version)
    end
  end
end
