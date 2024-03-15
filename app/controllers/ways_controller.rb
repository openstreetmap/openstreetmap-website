class WaysController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource

  around_action :web_timeout

  def show
    @type = "way"
    @feature = Way.preload(:way_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :nodes => [:node_tags, { :ways => :way_tags }]).find(params[:id])
    render "browse/feature"
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
