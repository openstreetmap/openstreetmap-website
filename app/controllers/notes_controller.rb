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
    param! :page, Integer, :min => 1

    @params = params.permit(:display_name, :status)
    @title = t ".title", :user => @user.display_name
    @page = (params[:page] || 1).to_i
    @page_size = 10
    @notes = @user.notes
    @notes = @notes.visible unless current_user&.moderator?
    @notes = @notes.where(:status => params[:status]) unless params[:status] == "all" || params[:status].blank?
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

    @note_includes_anonymous = @note.author.nil? || @note_comments.find { |comment| comment.author.nil? }

    @note_comments = @note_comments.drop(1) if @note_comments.first&.event == "opened"
  rescue ActiveRecord::RecordNotFound
    render :template => "browse/not_found", :status => :not_found
  end

  def new
    @anonymous_notes_count = request.cookies["_osm_anonymous_notes_count"].to_i || 0
    render :action => :new_readonly if api_status != "online"
  end
end
