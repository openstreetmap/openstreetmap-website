class OldWaysController < OldElementsController
  def index
    @type = "way"
    @feature = Way.preload(:way_tags, :old_ways => [:old_tags, { :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] } }]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "way"
    @feature = OldWay.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] }).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
