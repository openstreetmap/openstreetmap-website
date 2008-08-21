class DiaryEntryController < ApplicationController
  layout 'site', :except => :rss

  before_filter :authorize_web
  before_filter :require_user, :only => [:new, :edit]
  before_filter :check_database_availability

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

  def edit
    @title= 'edit diary entry'
    @diary_entry = DiaryEntry.find(params[:id])
    if @user != @diary_entry.user
	  redirect_to :controller => 'diary_entry', :action => 'view', :id => params[:id]
    end
    if params[:diary_entry]
      @diary_entry.title = params[:diary_entry][:title]
      @diary_entry.body = params[:diary_entry][:body]
      @diary_entry.latitude = params[:diary_entry][:latitude]
      @diary_entry.longitude = params[:diary_entry][:longitude]
      if @diary_entry.save
        redirect_to :controller => 'diary_entry', :action => 'view', :id => params[:id]
	  end
    end
  end

  def comment
    @entry = DiaryEntry.find(params[:id])
    @diary_comment = @entry.diary_comments.build(params[:diary_comment])
    @diary_comment.user = @user
    if @diary_comment.save
      Notifier::deliver_diary_comment_notification(@diary_comment)
      redirect_to :controller => 'diary_entry', :action => 'view', :display_name => @entry.user.display_name, :id => @entry.id
    else
      render :action => 'view'
    end
  end
  
  def list
    if params[:display_name]
      @this_user = User.find_by_display_name(params[:display_name])
      if @this_user
        @title = @this_user.display_name + "'s diary"
        @entry_pages, @entries = paginate(:diary_entries,
                                          :conditions => ['user_id = ?', @this_user.id],
                                          :order => 'created_at DESC',
                                          :per_page => 20)
      else
        @not_found_user = params[:display_name]

        render :action => 'no_such_user', :status => :not_found
      end
    else
      @title = "Users' diaries"
      @entry_pages, @entries = paginate(:diary_entries,
                                        :order => 'created_at DESC',
                                        :per_page => 20)
    end
  end

  def rss
    if params[:display_name]
      user = User.find_by_display_name(params[:display_name])

      if user
        @entries = DiaryEntry.find(:all, :conditions => ['user_id = ?', user.id], :order => 'created_at DESC', :limit => 20)
        @title = "OpenStreetMap diary entries for #{user.display_name}"
        @description = "Recent OpenStreetmap diary entries from #{user.display_name}"
        @link = "http://www.openstreetmap.org/user/#{user.display_name}/diary"

        render :content_type => Mime::RSS
      else
        render :nothing => true, :status => :not_found
      end
    else
      @entries = DiaryEntry.find(:all, :order => 'created_at DESC', :limit => 20)
      @title = "OpenStreetMap diary entries"
      @description = "Recent diary entries from users of OpenStreetMap"
      @link = "http://www.openstreetmap.org/diary"

      render :content_type => Mime::RSS
    end
  end

  def view
    user = User.find_by_display_name(params[:display_name])

    if user
      @entry = DiaryEntry.find(:first, :conditions => ['user_id = ? AND id = ?', user.id, params[:id]])
    else
      @not_found_user = params[:display_name]

      render :action => 'no_such_user', :status => :not_found
    end
  end
end
