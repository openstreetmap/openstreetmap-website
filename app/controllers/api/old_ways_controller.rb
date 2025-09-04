# frozen_string_literal: true

module Api
  class OldWaysController < OldElementsController
    private

    def lookup_old_element
      @old_element = OldWay
                     .includes(:old_nodes, :old_tags)
                     .find([params[:way_id], params[:version]])
    end

    def lookup_old_element_versions
      @elements = OldWay
                  .includes(:old_nodes, :old_tags)
                  .where(:way_id => params[:way_id])
                  .order(:version)
    end
  end
end
