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
  
  def list
    if params[:display_name]
      @this_user = User.find_by_display_name(params[:display_name])
      @title = @this_user.display_name + "'s diary"
      if params[:id]
        @entries=DiaryEntry.find(:all, :conditions => ['user_id = ? AND id = ?', @this_user.id, params[:id]])
      else
        @entries=DiaryEntry.find(:all, :conditions => ['user_id = ?', @this_user.id], :order => 'created_at DESC')
      end
    else
      @title = 'recent diary entries'
      @entries=DiaryEntry.find(:all, :order => 'created_at DESC', :limit => 20)
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
  end
end
