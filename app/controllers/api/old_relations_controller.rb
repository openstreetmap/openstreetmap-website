module Api
  class OldRelationsController < OldElementsController
    private

    def lookup_old_element
      @old_element = OldRelation.find([params[:relation_id], params[:version]])
    end

    def lookup_old_element_versions
      @elements = OldRelation.where(:relation_id => params[:relation_id]).order(:version)
    end
  end
end
