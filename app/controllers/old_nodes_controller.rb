class OldNodesController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource
  before_action -> { authorize! :show_redactions, OldNode if params[:show_redactions] }

  around_action :web_timeout

  def index
    @type = "node"
    @feature = Node.preload(:node_tags, :old_nodes => [:old_tags, { :changeset => [:changeset_tags, :user] }]).find(params[:id])
    render "browse/history"
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "node"
    @feature = OldNode.preload(:old_tags, :changeset => [:changeset_tags, :user]).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
