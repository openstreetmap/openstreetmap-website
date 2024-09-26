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

  ### Display a list of notes by a specified user
  def index
    param! :page, Integer, :min => 1

    @params = params.permit(:display_name, :from, :to, :status, :sort_by, :sort_order)
    @title = t ".title", :user => @user.display_name
    @page = (params[:page] || 1).to_i
    @page_size = 10
    @status = params[:status] || "open"

    @notes = @user.notes
    @notes = @notes.visible unless current_user&.moderator?

    case params[:status]
    when "open"
      @notes = @notes.where(:status => "open")
    when "closed"
      @notes = @notes.where(:status => "closed")
    end

    # Filter by date range (from, to)
    if params[:from].present?
      from_date = begin
        DateTime.parse(params[:from])
      rescue StandardError
        nil
      end
      @notes = @notes.where(:notes => { :created_at => from_date.. }) if from_date
    end

    if params[:to].present?
      to_date = begin
        DateTime.parse(params[:to])
      rescue StandardError
        nil
      end
      @notes = @notes.where(:notes => { :created_at => ..to_date }) if to_date
    end

    # Handle sorting
    sort_by = params[:sort_by] || "updated_at"
    sort_order = params[:sort_order] || "desc"
    @notes = @notes.order("#{sort_by} #{sort_order}")

    # Apply pagination and preload comments
    @notes = @notes.distinct.offset((@page - 1) * @page_size).limit(@page_size).preload(:comments => :author)

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
