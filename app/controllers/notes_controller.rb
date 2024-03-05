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
    @title = t ".title", :user => @user.display_name
    @params = params.permit(:display_name, :before, :after)

    notes = @user.notes
    notes = notes.visible unless current_user&.moderator?

    begin
      @notes = start_reading_at_params(notes)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t ".invalid_page"
      redirect_to :action => "index"
      return
    end

    @notes = @notes.distinct
    @notes = @notes.limit(10)
    @notes = @notes.preload(:comments => :author)
    @notes = @notes.sort_by { |note| [note.updated_at, note.id] }.reverse

    if @notes.count.positive?
      @newer_param = { :after => updated_at_and_id_param_value(@notes.first) } if notes.exists?(["(updated_at, notes.id) > (?, ?)", @notes.first.updated_at, @notes.first.id])
      @older_param = { :before => updated_at_and_id_param_value(@notes.last) } if notes.exists?(["(updated_at, notes.id) < (?, ?)", @notes.last.updated_at, @notes.last.id])
    else
      previous_newer_param = params[:before] || params[:to]
      previous_older_param = params[:after] || params[:from]
      @newer_param = { :from => "oldest" } if previous_newer_param && where_cursor(notes, ">", previous_newer_param).exists?
      @older_param = { :to => "newest" } if previous_older_param && where_cursor(notes, "<", previous_older_param).exists?
    end

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

  private

  def start_reading_at_params(notes)
    if params[:before]
      where_cursor(notes, "<", params[:before]).order(:updated_at => :desc, :id => :desc)
    elsif params[:after]
      where_cursor(notes, ">", params[:after]).order(:updated_at => :asc, :id => :asc)
    elsif params[:to]
      where_cursor(notes, "<=", params[:to]).order(:updated_at => :desc, :id => :desc)
    elsif params[:from]
      where_cursor(notes, ">=", params[:from]).order(:updated_at => :asc, :id => :asc)
    else
      notes.order(:updated_at => :desc, :id => :desc)
    end
  end

  def where_cursor(notes, op, param)
    if param.respond_to?(:keys)
      cursor_note = notes.find(param[:id])
      cursor_time = Time.parse(param[:updated_at]).utc
      if (cursor_time...(cursor_time + 1.second)).cover? cursor_note.updated_at
        notes.where("(updated_at, notes.id) #{op} (?, ?)", cursor_note.updated_at, cursor_note.id)
      else
        notes.where("updated_at #{op} ?", cursor_time)
      end
    elsif (param == "oldest" && op == ">=") || (param == "newest" && op == "<=")
      notes
    else
      cursor_note = notes.find(param)
      notes.where("(updated_at, notes.id) #{op} (?, ?)", cursor_note.updated_at, cursor_note.id)
    end
  end

  def updated_at_and_id_param_value(note)
    { :updated_at => time_param_value(note.updated_at), :id => note.id }
  end

  def time_param_value(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end
end
