class NodesController < ElementsController
  def show
    @type = "node"
    @feature = Node.preload(:node_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :ways => :way_tags).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
