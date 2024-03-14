class BrowseController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth
  before_action :update_totp, :only => [:query]
  around_action :web_timeout
  authorize_resource :class => false

  def relation
    @type = "relation"
    @feature = Relation.preload(:relation_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :relation_members => :member).find(params[:id])
    render "feature"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def way
    @type = "way"
    @feature = Way.preload(:way_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :nodes => [:node_tags, { :ways => :way_tags }]).find(params[:id])
    render "feature"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def node
    @type = "node"
    @feature = Node.preload(:node_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :ways => :way_tags).find(params[:id])
    render "feature"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def query; end
end
