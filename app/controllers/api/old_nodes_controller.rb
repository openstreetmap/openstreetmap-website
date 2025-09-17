# frozen_string_literal: true

module Api
  class OldNodesController < OldElementsController
    private

    def lookup_old_element
      @old_element = OldNode
                     .includes(:old_tags)
                     .find([params[:node_id], params[:version]])
    end

    def lookup_old_element_versions
      @elements = OldNode
                  .includes(:old_tags)
                  .where(:node_id => params[:node_id])
                  .order(:version)
    end
  end
end
