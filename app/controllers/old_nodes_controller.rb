# frozen_string_literal: true

class OldNodesController < OldElementsController
  def index
    @type = "node"
    @current_feature = @feature = Node.preload(:element_tags).find(params[:id])
    @old_features, @newer_features_version, @older_features_version = get_page_items(
      OldNode.where(:node_id => params[:id]),
      :cursor_column => :version,
      :includes => [:old_tags, { :changeset => [:changeset_tags, :user] }]
    )

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "node"
    @current_feature = Node.find(params[:id])
    @feature = OldNode.preload(:old_tags, :changeset => [:changeset_tags, :user]).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
