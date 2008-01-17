class DiaryEntryController < ApplicationController
  layout 'site', :except => :rss

  before_filter :authorize_web
  before_filter :require_user, :only => [:new]

  def new
    @title = 'new diary entry'
    if params[:diary_entry]     
      @diary_entry = DiaryEntry.new(params[:diary_entry])
      @diary_entry.user = @user
      if @diary_entry.save 
        redirect_to :controller => 'diary_entry', :action => 'list', :display_name => @user.display_name 
      end
    end
  end

  def comment
    @entry = DiaryEntry.find(params[:id])
    @diary_comment = @entry.diary_comments.build(params[:diary_comment])
    @diary_comment.user = @user
    if @diary_comment.save
      redirect_to :controller => 'diary_entry', :action => 'view', :display_name => @entry.user.display_name, :id => @entry.id
    else
      render :action => 'view'
    end
  end
  
  def list
    if params[:display_name]
      @this_user = User.find_by_display_name(params[:display_name])
      @title = @this_user.display_name + "'s diary"
      @entries = DiaryEntry.find(:all, :conditions => ['user_id = ?', @this_user.id], :order => 'created_at DESC')
    else
      @title = "Users' diaries"
      @entries = DiaryEntry.find(:all, :order => 'created_at DESC', :limit => 20)
    end
  end

  def rss
    if params[:display_name]
      user = User.find_by_display_name(params[:display_name])
      @entries = DiaryEntry.find(:all, :conditions => ['user_id = ?', user.id], :order => 'created_at DESC', :limit => 20)
      @title = "OpenStreetMap diary entries for #{user.display_name}"
      @description = "Recent OpenStreetmap diary entries from #{user.display_name}"
      @link = "http://www.openstreetmap.org/user/#{user.display_name}/diary"
    else
      @entries = DiaryEntry.find(:all, :order => 'created_at DESC', :limit => 20)
      @title = "OpenStreetMap diary entries"
      @description = "Recent diary entries from users of OpenStreetMap"
      @link = "http://www.openstreetmap.org/diary"
    end

    render :content_type => Mime::RSS
  end

  def view
    user = User.find_by_display_name(params[:display_name])
    @entry = DiaryEntry.find(:first, :conditions => ['user_id = ? AND id = ?', user.id, params[:id]])
  end
end
