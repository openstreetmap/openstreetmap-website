class DiaryEntryController < ApplicationController
  layout 'site', :except => :rss

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:new, :edit]
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:new, :edit]

  def new
    @title = t 'diary_entry.new.title'

    if params[:diary_entry]     
      @diary_entry = DiaryEntry.new(params[:diary_entry])
      @diary_entry.user = @user

      if @diary_entry.save 
        redirect_to :controller => 'diary_entry', :action => 'list', :display_name => @user.display_name 
      else
        render :action => 'edit'
      end
    else
      @diary_entry = DiaryEntry.new(:language_code => @user.preferred_language)
      render :action => 'edit'
    end
  end

  def edit
    @title= t 'diary_entry.edit.title'
    @diary_entry = DiaryEntry.find(params[:id])

    if @user != @diary_entry.user
      redirect_to :controller => 'diary_entry', :action => 'view', :id => params[:id]
    elsif params[:diary_entry]
      if @diary_entry.update_attributes(params[:diary_entry])
        redirect_to :controller => 'diary_entry', :action => 'view', :id => params[:id]
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
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
      @this_user = User.find_by_display_name(params[:display_name], :conditions => {:visible => true})

      if @this_user
        @title = t 'diary_entry.list.user_title', :user => @this_user.display_name
        @entry_pages, @entries = paginate(:diary_entries,
                                          :conditions => ['user_id = ?', @this_user.id],
                                          :order => 'created_at DESC',
                                          :per_page => 20)
      else
        @title = t'diary_entry.no_such_user.title'
        @not_found_user = params[:display_name]

        render :action => 'no_such_user', :status => :not_found
      end
    else
      @title = t 'diary_entry.list.title'
      @entry_pages, @entries = paginate(:diary_entries, :include => :user,
                                        :conditions => ["users.visible = ?", true],
                                        :order => 'created_at DESC',
                                        :per_page => 20)
    end
  end

  def rss
    request.format = :rss

    if params[:display_name]
      user = User.find_by_display_name(params[:display_name], :conditions => {:visible => true})

      if user
        @entries = DiaryEntry.find(:all, :conditions => ['user_id = ?', user.id], :order => 'created_at DESC', :limit => 20)
        @title = "OpenStreetMap diary entries for #{user.display_name}"
        @description = "Recent OpenStreetmap diary entries from #{user.display_name}"
        @link = "http://#{SERVER_URL}/user/#{user.display_name}/diary"
      else
        render :nothing => true, :status => :not_found
      end
    elsif params[:language]
      @entries = DiaryEntry.find(:all, :include => :user,
        :conditions => ["users.visible = ? AND diary_entries.language = ?", true, params[:language]],
        :order => 'created_at DESC', :limit => 20)
      @title = "OpenStreetMap diary entries in #{params[:language]}"
      @description = "Recent diary entries from users of OpenStreetMap"
      @link = "http://#{SERVER_URL}/diary/#{params[:language]}"
    else
      @entries = DiaryEntry.find(:all, :include => :user,
                                 :conditions => ["users.visible = ?", true],
                                 :order => 'created_at DESC', :limit => 20)
      @title = "OpenStreetMap diary entries"
      @description = "Recent diary entries from users of OpenStreetMap"
      @link = "http://#{SERVER_URL}/diary"
    end
  end

  def view
    user = User.find_by_display_name(params[:display_name], :conditions => {:visible => true})

    if user
      @entry = DiaryEntry.find(:first, :conditions => ['user_id = ? AND id = ?', user.id, params[:id]])
      if @entry
        @title = t 'diary_entry.view.title', :user => params[:display_name]
      else
        render :action => 'no_such_entry', :status => :not_found
      end
    else
      @not_found_user = params[:display_name]

      render :action => 'no_such_user', :status => :not_found
    end
  end
end
