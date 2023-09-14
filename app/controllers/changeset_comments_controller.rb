class ChangesetCommentsController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user
  before_action -> { check_database_readable(:need_api => true) }
  around_action :web_timeout

  def index
    @title = t ".title", :user => @user.display_name
    @comments = []
  end
end
