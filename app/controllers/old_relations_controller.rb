class OldRelationsController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource

  around_action :web_timeout

  def show
    @type = "relation"
    @feature = OldRelation.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_members => :member).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
