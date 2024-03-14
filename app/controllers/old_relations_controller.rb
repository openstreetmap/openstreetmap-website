class OldRelationsController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth

  authorize_resource

  before_action :require_moderator_for_unredacted_history
  around_action :web_timeout

  def index
    @type = "relation"
    @feature = Relation.preload(:relation_tags, :old_relations => [:old_tags, { :changeset => [:changeset_tags, :user], :old_members => :member }]).find(params[:id])
    render "browse/history"
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "relation"
    @feature = OldRelation.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_members => :member).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  private

  def require_moderator_for_unredacted_history
    deny_access(nil) if params[:show_redactions] && !current_user&.moderator?
  end
end
