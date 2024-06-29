class ChangesetCommentsController < ApplicationController
  include UserMethods
  include PaginationMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user
  before_action -> { check_database_readable(:need_api => true) }
  around_action :web_timeout

  def index
    @title = t ".title", :user => @user.display_name

    comments = ChangesetComment.where(:author => @user)
    comments = comments.visible unless current_user&.moderator?

    @params = params.permit(:display_name, :before, :after)

    @comments, @newer_comments_id, @older_comments_id = get_page_items(comments, :includes => [:author])
  end
end
