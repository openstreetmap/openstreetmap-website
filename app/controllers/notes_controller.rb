class NotesController < ApplicationController
  layout :map_layout

  before_action :check_api_readable
  before_action :authorize_web
  before_action :require_oauth

  authorize_resource

  before_action :set_locale
  around_action :web_timeout

  ##
  # Display a list of notes by a specified user
  def index
    if params[:display_name]
      if @user = User.active.find_by(:display_name => params[:display_name])
        @params = params.permit(:display_name)
        @title = t ".title", :user => @user.display_name
        @page = (params[:page] || 1).to_i
        @page_size = 10
        @notes = @user.notes
        @notes = @notes.visible unless current_user&.moderator?
        @notes = @notes.order("updated_at DESC, id").distinct.offset((@page - 1) * @page_size).limit(@page_size).preload(:comments => :author)

        render :layout => "site"
      else
        @title = t "users.no_such_user.title"
        @not_found_user = params[:display_name]

        render :template => "users/no_such_user", :status => :not_found, :layout => "site"
      end
    end
  end

  def new; end
end
