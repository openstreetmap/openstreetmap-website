class WaysController < ElementsController
  def show
    @type = "way"
    @feature = Way.preload(:way_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :nodes => [:node_tags, { :ways => :way_tags }]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
