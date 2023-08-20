class NotesController < ApplicationController
  include UserMethods

  layout :map_layout

  before_action :check_api_readable
  before_action :authorize_web
  before_action :require_oauth

  authorize_resource

  before_action :lookup_user, :only => [:index]
  before_action :set_locale
  around_action :web_timeout

  ##
  # Display a list of notes by a specified user
  def index
    @params = params.permit(:display_name)
    @title = t ".title", :user => @user.display_name
    @page = (params[:page] || 1).to_i
    @page_size = 10
    @notes = @user.notes
    @notes = @notes.visible unless current_user&.moderator?
    @notes = @notes.order("updated_at DESC, id").distinct.offset((@page - 1) * @page_size).limit(@page_size).preload(:comments => :author)

    render :layout => "site"
  end

  def show
    @type = "note"

    if current_user&.moderator?
      @note = Note.find(params[:id])
      @note_comments = @note.comments.unscope(:where => :visible)
    else
      @note = Note.visible.find(params[:id])
      @note_comments = @note.comments
    end
  rescue ActiveRecord::RecordNotFound
    render :template => "browse/not_found", :status => :not_found
  end

  def new; end
end
