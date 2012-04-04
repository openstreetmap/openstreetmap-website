class OldWayController < OldController

  private
  
  def lookup_old_element
    @old_element = OldWay.find([params[:id], params[:version]])
  end

  def lookup_old_elements_via_current
    way = Way.find(params[:id])
    @elements = way.old_ways
  end
end
