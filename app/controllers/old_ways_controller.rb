class OldWaysController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource
  before_action -> { authorize! :show_redactions, OldWay if params[:show_redactions] }

  around_action :web_timeout

  def index
    @type = "way"
    @feature = Way.preload(:way_tags, :old_ways => [:old_tags, { :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] } }]).find(params[:id])
    render "browse/history"
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "way"
    @feature = OldWay.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] }).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
