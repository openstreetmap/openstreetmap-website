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

    @notes = if params[:before]
               cursor_note = Note.find(params[:before]) # TODO 404 or bad user input
               notes.where("(updated_at, notes.id) < (?, ?)", cursor_note.updated_at, cursor_note.id).order(:updated_at => :desc, :id => :desc)
             elsif params[:after]
               cursor_note = Note.find(params[:after])
               notes.where("(updated_at, notes.id) > (?, ?)", cursor_note.updated_at, cursor_note.id).order(:updated_at => :asc, :id => :asc)
             else
               notes.order(:updated_at => :desc, :id => :desc)
             end

    @notes = @notes.distinct
    @notes = @notes.limit(10)
    @notes = @notes.preload(:comments => :author)
    @notes = @notes.sort_by { |note| [note.updated_at, note.id] }.reverse

    @newer_notes = @notes.count.positive? && notes.exists?(["(updated_at, notes.id) > (?, ?)", @notes.first.updated_at, @notes.first.id])
    @older_notes = @notes.count.positive? && notes.exists?(["(updated_at, notes.id) < (?, ?)", @notes.last.updated_at, @notes.last.id])

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
