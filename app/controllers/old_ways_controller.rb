class OldWaysController < OldElementsController
  def index
    @type = "way"
    @feature = Way.preload(:way_tags).find(params[:id])
    @old_features, @newer_features_version, @older_features_version = get_page_items(
      OldWay.where(:way_id => params[:id]),
      :cursor_column => :version,
      :includes => [:old_tags, { :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] } }]
    )
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
