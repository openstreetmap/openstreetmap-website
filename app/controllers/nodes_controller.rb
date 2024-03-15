class NodesController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource

  around_action :web_timeout

  def show
    @type = "node"
    @feature = Node.preload(:node_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :ways => :way_tags).find(params[:id])
    render "browse/feature"
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
