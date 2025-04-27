# frozen_string_literal: true

class DiaryCommentsController < ApplicationController
  layout :site_layout

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable

  allow_thirdparty_images :only => :create

  def create
    @diary_entry = DiaryEntry.find(params[:id])
    @comments = @diary_entry.visible_comments
    @diary_comment = @diary_entry.comments.build(comment_params)
    @diary_comment.user = current_user
    if @diary_comment.save

      # Notify current subscribers of the new comment
      @diary_entry.subscribers.visible.each do |user|
        UserMailer.diary_comment_notification(@diary_comment, user).deliver_later if current_user != user
      end

      # Add the commenter to the subscribers if necessary
      @diary_entry.subscriptions.create(:user => current_user) unless @diary_entry.subscribers.exists?(current_user.id)

      redirect_to diary_entry_path(@diary_entry.user, @diary_entry, :anchor => "comment#{@diary_comment.id}")
    else
      render :action => "new"
    end
  rescue ActiveRecord::RecordNotFound
    render "diary_entries/no_such_entry", :status => :not_found
  end

  def hide
    comment = DiaryComment.find(params[:comment])
    comment.update(:visible => false)
    redirect_to diary_entry_path(comment.diary_entry.user, comment.diary_entry)
  end

  def unhide
    comment = DiaryComment.find(params[:comment])
    comment.update(:visible => true)
    redirect_to diary_entry_path(comment.diary_entry.user, comment.diary_entry)
  end

  private

  ##
  # return permitted diary comment parameters
  def comment_params
    params.expect(:diary_comment => [:body])
  end
end
