# frozen_string_literal: true

module Api
  class OldRelationsController < OldElementsController
    private

    def lookup_old_element
      @old_element = OldRelation
                     .includes(:old_members, :old_tags)
                     .find(params.expect(:relation_id, :version))
    end

    def lookup_old_element_versions
      @elements = OldRelation
                  .includes(:old_members, :old_tags)
                  .where(:relation_id => params[:relation_id])
                  .order(:version)
    end
  end
end
