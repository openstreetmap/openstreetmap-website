class DiaryEntryController < ApplicationController
  layout 'site', :except => :rss

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:new, :edit, :comment, :hide, :hidecomment]
  before_filter :lookup_this_user, :only => [:view, :comments]
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:new, :edit]
  before_filter :require_administrator, :only => [:hide, :hidecomment]

#  caches_action :list, :layout => false, :unless => :user_specific_list?
  caches_action :rss, :layout => true
#  caches_action :view, :layout => false
  cache_sweeper :diary_sweeper, :only => [:new, :edit, :comment, :hide, :hidecomment]

  def new
    @title = t 'diary_entry.new.title'

    if params[:diary_entry]
      @diary_entry = DiaryEntry.new(params[:diary_entry])
      @diary_entry.user = @user

      if @diary_entry.save
        default_lang = @user.preferences.where(:k => "diary.default_language").first
        if default_lang
          default_lang.v = @diary_entry.language_code
          default_lang.save!
        else
          @user.preferences.create(:k => "diary.default_language", :v => @diary_entry.language_code)
        end
        redirect_to :controller => 'diary_entry', :action => 'list', :display_name => @user.display_name
      else
        render :action => 'edit'
      end
    else
      default_lang = @user.preferences.where(:k => "diary.default_language").first
      lang_code = default_lang ? default_lang.v : @user.preferred_language
      @diary_entry = DiaryEntry.new(:language_code => lang_code)
      set_map_location
      render :action => 'edit'
    end
  end

  def edit
    @title= t 'diary_entry.edit.title'
    @diary_entry = DiaryEntry.find(params[:id])

    if @user != @diary_entry.user
      redirect_to :controller => 'diary_entry', :action => 'view', :id => params[:id]
    elsif params[:diary_entry] and @diary_entry.update_attributes(params[:diary_entry])
      redirect_to :controller => 'diary_entry', :action => 'view', :id => params[:id]
    end

    set_map_location
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def comment
    @entry = DiaryEntry.find(params[:id])
    @diary_comment = @entry.comments.build(params[:diary_comment])
    @diary_comment.user = @user
    if @diary_comment.save
      if @diary_comment.user != @entry.user
        Notifier.diary_comment_notification(@diary_comment).deliver
      end

      redirect_to :controller => 'diary_entry', :action => 'view', :display_name => @entry.user.display_name, :id => @entry.id
    else
      render :action => 'view'
    end
  end

  def list
    if params[:display_name]
      @this_user = User.active.find_by_display_name(params[:display_name])

      if @this_user
        @title = t 'diary_entry.list.user_title', :user => @this_user.display_name
        @entry_pages, @entries = paginate(:diary_entries,
                                          :conditions => {
                                            :user_id => @this_user.id,
                                            :visible => true
                                          },
                                          :order => 'created_at DESC',
                                          :per_page => 20)
      else
        render_unknown_user params[:display_name]
      end
    elsif params[:language]
      @title = t 'diary_entry.list.in_language_title', :language => Language.find(params[:language]).english_name
      @entry_pages, @entries = paginate(:diary_entries, :include => :user,
                                        :conditions => {
                                          :users => { :status => ["active", "confirmed"] },
                                          :visible => true,
                                          :language_code => params[:language]
                                        },
                                        :order => 'created_at DESC',
                                        :per_page => 20)
    elsif params[:friends]
      if @user
        @title = t 'diary_entry.list.title_friends'
        @entry_pages, @entries = paginate(:diary_entries, :include => :user,
                                          :conditions => {
                                            :user_id => @user.friend_users,
                                            :visible => true
                                          },
                                          :order => 'created_at DESC',
                                          :per_page => 20)
      else
          require_user
          return
      end
    elsif params[:nearby]
      if @user
        @title = t 'diary_entry.list.title_nearby'
        @entry_pages, @entries = paginate(:diary_entries, :include => :user,
                                          :conditions => {
                                            :user_id => @user.nearby,
                                            :visible => true
                                          },
                                          :order => 'created_at DESC',
                                          :per_page => 20)
      else
          require_user
          return
      end
    else
      @title = t 'diary_entry.list.title'
      @entry_pages, @entries = paginate(:diary_entries, :include => :user,
                                        :conditions => {
                                          :users => { :status => ["active", "confirmed"] },
                                          :visible => true
                                        },
                                        :order => 'created_at DESC',
                                        :per_page => 20)
    end
  end

  def rss
    @entries = DiaryEntry.includes(:user).order("created_at DESC").limit(20)

    if params[:display_name]
      user = User.active.find_by_display_name(params[:display_name])

      if user
        @entries = user.diary_entries.visible
        @title = I18n.t('diary_entry.feed.user.title', :user => user.display_name)
        @description = I18n.t('diary_entry.feed.user.description', :user => user.display_name)
        @link = "http://#{SERVER_URL}/user/#{user.display_name}/diary"
      else
        render :nothing => true, :status => :not_found
      end
    elsif params[:language]
      @entries = @entries.visible.where(:language_code => params[:language]).joins(:user).where(:users => { :status => ["active", "confirmed"] })
      @title = I18n.t('diary_entry.feed.language.title', :language_name => Language.find(params[:language]).english_name)
      @description = I18n.t('diary_entry.feed.language.description', :language_name => Language.find(params[:language]).english_name)
      @link = "http://#{SERVER_URL}/diary/#{params[:language]}"
    else
      @entries = @entries.visible.joins(:user).where(:users => { :status => ["active", "confirmed"] })
      @title = I18n.t('diary_entry.feed.all.title')
      @description = I18n.t('diary_entry.feed.all.description')
      @link = "http://#{SERVER_URL}/diary"
    end
  end

  def view
    @entry = @this_user.diary_entries.visible.where(:id => params[:id]).first
    if @entry
      @title = t 'diary_entry.view.title', :user => params[:display_name], :title => @entry.title
    else
      @title = t 'diary_entry.no_such_entry.title', :id => params[:id]
      render :action => 'no_such_entry', :status => :not_found
    end
  end

  def hide
    entry = DiaryEntry.find(params[:id])
    entry.update_attributes({:visible => false}, :without_protection => true)
    redirect_to :action => "list", :display_name => entry.user.display_name
  end

  def hidecomment
    comment = DiaryComment.find(params[:comment])
    comment.update_attributes({:visible => false}, :without_protection => true)
    redirect_to :action => "view", :display_name => comment.diary_entry.user.display_name, :id => comment.diary_entry.id
  end

  def comments
    @comment_pages, @comments = paginate(:diary_comments,
                                         :conditions => {
                                           :user_id => @this_user,
                                           :visible => true
                                         },
                                         :order => 'created_at DESC',
                                         :per_page => 20)
    @page = (params[:page] || 1).to_i
  end
private
  ##
  # require that the user is a administrator, or fill out a helpful error message
  # and return them to the user page.
  def require_administrator
    unless @user.administrator?
      flash[:error] = t('user.filter.not_an_administrator')
      redirect_to :controller => 'diary_entry', :action => 'view', :display_name => params[:id]
    end
  end

  ##
  # is this list user specific?
  def user_specific_list?
    params[:friends] or params[:nearby]
  end

  ##
  # decide on a location for the diary entry map
  def set_map_location
    if @diary_entry.latitude and @diary_entry.longitude
      @lon = @diary_entry.longitude
      @lat = @diary_entry.latitude
      @zoom = 12
    elsif @user.home_lat.nil? or @user.home_lon.nil?
      @lon = params[:lon] || -0.1
      @lat = params[:lat] || 51.5
      @zoom = params[:zoom] || 4
    else
      @lon = @user.home_lon
      @lat = @user.home_lat
      @zoom = 12
    end
  end
end
