class DiaryEntryController < ApplicationController
  layout "site", :except => :rss

  before_action :authorize_web
  before_action :set_locale
  before_action :require_user, :only => [:new, :edit, :comment, :hide, :hidecomment, :subscribe, :unsubscribe]
  before_action :lookup_this_user, :only => [:view, :comments]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:new, :edit, :comment, :hide, :hidecomment, :subscribe, :unsubscribe]
  before_action :require_administrator, :only => [:hide, :hidecomment]

  def new
    @title = t "diary_entry.new.title"

    if params[:diary_entry]
      @diary_entry = DiaryEntry.new(entry_params)
      @diary_entry.user = @user

      if @diary_entry.save
        default_lang = @user.preferences.where(:k => "diary.default_language").first
        if default_lang
          default_lang.v = @diary_entry.language_code
          default_lang.save!
        else
          @user.preferences.create(:k => "diary.default_language", :v => @diary_entry.language_code)
        end

        # Subscribe user to diary comments
        @diary_entry.subscribers << @user

        redirect_to :controller => "diary_entry", :action => "list", :display_name => @user.display_name
      else
        render :action => "edit"
      end
    else
      default_lang = @user.preferences.where(:k => "diary.default_language").first
      lang_code = default_lang ? default_lang.v : @user.preferred_language
      @diary_entry = DiaryEntry.new(:language_code => lang_code)
      set_map_location
      render :action => "edit"
    end
  end

  def edit
    @title = t "diary_entry.edit.title"
    @diary_entry = DiaryEntry.find(params[:id])

    if @user != @diary_entry.user
      redirect_to :controller => "diary_entry", :action => "view", :id => params[:id]
    elsif params[:diary_entry] && @diary_entry.update_attributes(entry_params)
      redirect_to :controller => "diary_entry", :action => "view", :id => params[:id]
    end

    set_map_location
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def comment
    @entry = DiaryEntry.find(params[:id])
    @diary_comment = @entry.comments.build(comment_params)
    @diary_comment.user = @user
    if @diary_comment.save

      # Notify current subscribers of the new comment
      @entry.subscribers.visible.each do |user|
        if @user != user
          Notifier.diary_comment_notification(@diary_comment, user).deliver_now
        end
      end

      # Add the commenter to the subscribers if necessary
      @entry.subscribers << @user unless @entry.subscribers.exists?(@user.id)

      redirect_to :controller => "diary_entry", :action => "view", :display_name => @entry.user.display_name, :id => @entry.id
    else
      render :action => "view"
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def subscribe
    @entry = DiaryEntry.find(params[:id])

    if ! diary_entry.subscribers.exists?(@user.id)
      diary_entry.subscribers << @user

    redirect_to :controller => "diary_entry", :action => "view", :display_name => diary_entry.user.display_name, :id => diary_entry.id
  end

  def unsubscribe
    @entry = DiaryEntry.find(params[:id])

    if diary_entry.subscribers.exists?(@user.id)
      diary_entry.subscribers.delete(@user)

    redirect_to :controller => "diary_entry", :action => "view", :display_name => diary_entry.user.display_name, :id => diary_entry.id
  end

  def list
    if params[:display_name]
      @this_user = User.active.find_by_display_name(params[:display_name])

      if @this_user
        @title = t "diary_entry.list.user_title", :user => @this_user.display_name
        @entries = @this_user.diary_entries
      else
        render_unknown_user params[:display_name]
        return
      end
    elsif params[:friends]
      if @user
        @title = t "diary_entry.list.title_friends"
        @entries = DiaryEntry.where(:user_id => @user.friend_users)
      else
        require_user
        return
      end
    elsif params[:nearby]
      if @user
        @title = t "diary_entry.list.title_nearby"
        @entries = DiaryEntry.where(:user_id => @user.nearby)
      else
        require_user
        return
      end
    else
      @entries = DiaryEntry.joins(:user).where(:users => { :status => %w(active confirmed) })

      if params[:language]
        @title = t "diary_entry.list.in_language_title", :language => Language.find(params[:language]).english_name
        @entries = @entries.where(:language_code => params[:language])
      else
        @title = t "diary_entry.list.title"
      end
    end

    @page = (params[:page] || 1).to_i
    @page_size = 20

    @entries = @entries.visible
    @entries = @entries.order("created_at DESC")
    @entries = @entries.offset((@page - 1) * @page_size)
    @entries = @entries.limit(@page_size)
    @entries = @entries.includes(:user, :language)
  end

  def rss
    if params[:display_name]
      user = User.active.find_by_display_name(params[:display_name])

      if user
        @entries = user.diary_entries
        @title = I18n.t("diary_entry.feed.user.title", :user => user.display_name)
        @description = I18n.t("diary_entry.feed.user.description", :user => user.display_name)
        @link = "http://#{SERVER_URL}/user/#{user.display_name}/diary"
      else
        render :text => "", :status => :not_found
        return
      end
    else
      @entries = DiaryEntry.joins(:user).where(:users => { :status => %w(active confirmed) })

      if params[:language]
        @entries = @entries.where(:language_code => params[:language])
        @title = I18n.t("diary_entry.feed.language.title", :language_name => Language.find(params[:language]).english_name)
        @description = I18n.t("diary_entry.feed.language.description", :language_name => Language.find(params[:language]).english_name)
        @link = "http://#{SERVER_URL}/diary/#{params[:language]}"
      else
        @title = I18n.t("diary_entry.feed.all.title")
        @description = I18n.t("diary_entry.feed.all.description")
        @link = "http://#{SERVER_URL}/diary"
      end
    end

    @entries = @entries.visible.includes(:user).order("created_at DESC").limit(20)
  end

  def view
    @entry = @this_user.diary_entries.visible.where(:id => params[:id]).first
    if @entry
      @title = t "diary_entry.view.title", :user => params[:display_name], :title => @entry.title
    else
      @title = t "diary_entry.no_such_entry.title", :id => params[:id]
      render :action => "no_such_entry", :status => :not_found
    end
  end

  def hide
    entry = DiaryEntry.find(params[:id])
    entry.update_attributes(:visible => false)
    redirect_to :action => "list", :display_name => entry.user.display_name
  end

  def hidecomment
    comment = DiaryComment.find(params[:comment])
    comment.update_attributes(:visible => false)
    redirect_to :action => "view", :display_name => comment.diary_entry.user.display_name, :id => comment.diary_entry.id
  end

  def comments
    @comment_pages, @comments = paginate(:diary_comments,
                                         :conditions => {
                                           :user_id => @this_user,
                                           :visible => true
                                         },
                                         :order => "created_at DESC",
                                         :per_page => 20)
    @page = (params[:page] || 1).to_i
  end

  private

  ##
  # return permitted diary entry parameters
  def entry_params
    params.require(:diary_entry).permit(:title, :body, :language_code, :latitude, :longitude)
  end

  ##
  # return permitted diary comment parameters
  def comment_params
    params.require(:diary_comment).permit(:body)
  end

  ##
  # require that the user is a administrator, or fill out a helpful error message
  # and return them to the user page.
  def require_administrator
    unless @user.administrator?
      flash[:error] = t("user.filter.not_an_administrator")
      redirect_to :controller => "diary_entry", :action => "view"
    end
  end

  ##
  # decide on a location for the diary entry map
  def set_map_location
    if @diary_entry.latitude && @diary_entry.longitude
      @lon = @diary_entry.longitude
      @lat = @diary_entry.latitude
      @zoom = 12
    elsif @user.home_lat.nil? || @user.home_lon.nil?
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
