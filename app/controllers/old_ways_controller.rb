class OldWaysController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource

  around_action :web_timeout

  def show
    @type = "way"
    @feature = OldWay.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] }).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
