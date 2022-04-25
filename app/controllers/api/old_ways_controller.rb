module Api
  class OldWaysController < OldController
    private

    def lookup_old_element
      @old_element = OldWay.find([params[:id], params[:version]])
    end

    def lookup_old_element_versions
      @elements = OldWay.where(:way_id => params[:id]).order(:version)
    end
  end
end
