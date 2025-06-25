class OldNodesController < OldElementsController
  def index
    @type = "node"
    @feature = Node.preload(:node_tags, :old_nodes => [:old_tags, { :changeset => [:changeset_tags, :user] }]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "node"
    @feature = OldNode.preload(:old_tags, :changeset => [:changeset_tags, :user]).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
