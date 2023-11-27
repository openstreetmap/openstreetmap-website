class DiaryEntriesController < ApplicationController
  include UserMethods

  layout "site", :except => :rss

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :lookup_user, :only => [:show, :comments]
  before_action :check_database_writable, :only => [:new, :create, :edit, :update, :comment, :hide, :hidecomment, :subscribe, :unsubscribe]
  before_action :allow_thirdparty_images, :only => [:new, :create, :edit, :update, :index, :show, :comments]

  def index
    if params[:display_name]
      @user = User.active.find_by(:display_name => params[:display_name])

      if @user
        @title = t ".user_title", :user => @user.display_name
        entries = @user.diary_entries
      else
        render_unknown_user params[:display_name]
        return
      end
    elsif params[:friends]
      if current_user
        @title = t ".title_friends"
        entries = DiaryEntry.where(:user => current_user.friends)
      else
        require_user
        return
      end
    elsif params[:nearby]
      if current_user
        @title = t ".title_nearby"
        entries = DiaryEntry.where(:user => current_user.nearby)
      else
        require_user
        return
      end
    else
      entries = DiaryEntry.joins(:user).where(:users => { :status => %w[active confirmed] })

      if params[:language]
        @title = t ".in_language_title", :language => Language.find(params[:language]).english_name
        entries = entries.where(:language_code => params[:language])
      else
        @title = t ".title"
      end
    end

    entries = entries.visible unless can? :unhide, DiaryEntry

    @params = params.permit(:display_name, :friends, :nearby, :language)

    @entries, @newer_entries_id, @older_entries_id = get_page_items(entries, [:user, :language])
  end

  def show
    entries = @user.diary_entries
    entries = entries.visible unless can? :unhide, DiaryEntry
    @entry = entries.find_by(:id => params[:id])
    if @entry
      @title = t ".title", :user => params[:display_name], :title => @entry.title
      @comments = can?(:unhidecomment, DiaryEntry) ? @entry.comments : @entry.visible_comments
    else
      @title = t "diary_entries.no_such_entry.title", :id => params[:id]
      render :action => "no_such_entry", :status => :not_found
    end
  end

  def new
    @title = t ".title"

    default_lang = current_user.preferences.find_by(:k => "diary.default_language")
    lang_code = default_lang ? default_lang.v : current_user.preferred_language
    @diary_entry = DiaryEntry.new(entry_params.merge(:language_code => lang_code))
    set_map_location
    render :action => "new"
  end

  def edit
    @title = t ".title"
    @diary_entry = DiaryEntry.find(params[:id])

    redirect_to diary_entry_path(@diary_entry.user, @diary_entry) if current_user != @diary_entry.user

    set_map_location
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def create
    @title = t "diary_entries.new.title"

    @diary_entry = DiaryEntry.new(entry_params)
    @diary_entry.user = current_user

    if @diary_entry.save
      default_lang = current_user.preferences.find_by(:k => "diary.default_language")
      if default_lang
        default_lang.v = @diary_entry.language_code
        default_lang.save!
      else
        current_user.preferences.create(:k => "diary.default_language", :v => @diary_entry.language_code)
      end

      # Subscribe user to diary comments
      @diary_entry.subscriptions.create(:user => current_user)

      redirect_to :action => "index", :display_name => current_user.display_name
    else
      render :action => "new"
    end
  end

  def update
    @title = t "diary_entries.edit.title"
    @diary_entry = DiaryEntry.find(params[:id])

    if current_user != @diary_entry.user ||
       (params[:diary_entry] && @diary_entry.update(entry_params))
      redirect_to diary_entry_path(@diary_entry.user, @diary_entry)
    else
      set_map_location
      render :action => "edit"
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def comment
    @entry = DiaryEntry.find(params[:id])
    @comments = @entry.visible_comments
    @diary_comment = @entry.comments.build(comment_params)
    @diary_comment.user = current_user
    if @diary_comment.save

      # Notify current subscribers of the new comment
      @entry.subscribers.visible.each do |user|
        UserMailer.diary_comment_notification(@diary_comment, user).deliver_later if current_user != user
      end

      # Add the commenter to the subscribers if necessary
      @entry.subscriptions.create(:user => current_user) unless @entry.subscribers.exists?(current_user.id)

      redirect_to diary_entry_path(@entry.user, @entry)
    else
      render :action => "show"
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def subscribe
    diary_entry = DiaryEntry.find(params[:id])

    diary_entry.subscriptions.create(:user => current_user) unless diary_entry.subscribers.exists?(current_user.id)

    redirect_to diary_entry_path(diary_entry.user, diary_entry)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def unsubscribe
    diary_entry = DiaryEntry.find(params[:id])

    diary_entry.subscriptions.where(:user => current_user).delete_all if diary_entry.subscribers.exists?(current_user.id)

    redirect_to diary_entry_path(diary_entry.user, diary_entry)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def rss
    if params[:display_name]
      user = User.active.find_by(:display_name => params[:display_name])

      if user
        @entries = user.diary_entries
        @title = t("diary_entries.feed.user.title", :user => user.display_name)
        @description = t("diary_entries.feed.user.description", :user => user.display_name)
        @link = url_for :action => "index", :display_name => user.display_name, :host => Settings.server_url, :protocol => Settings.server_protocol
      else
        head :not_found
        return
      end
    else
      @entries = DiaryEntry.joins(:user).where(:users => { :status => %w[active confirmed] })

      # Items can't be flagged as deleted in the RSS format.
      # For the general feeds, allow a delay before publishing, to help spam fighting
      @entries = @entries.where("created_at < :time", :time => Settings.diary_feed_delay.hours.ago)

      if params[:language]
        @entries = @entries.where(:language_code => params[:language])
        @title = t("diary_entries.feed.language.title", :language_name => Language.find(params[:language]).english_name)
        @description = t("diary_entries.feed.language.description", :language_name => Language.find(params[:language]).english_name)
        @link = url_for :action => "index", :language => params[:language], :host => Settings.server_url, :protocol => Settings.server_protocol
      else
        @title = t("diary_entries.feed.all.title")
        @description = t("diary_entries.feed.all.description")
        @link = url_for :action => "index", :host => Settings.server_url, :protocol => Settings.server_protocol
      end
    end
    @entries = @entries.visible.includes(:user).order("created_at DESC").limit(20)
  end

  def hide
    entry = DiaryEntry.find(params[:id])
    entry.update(:visible => false)
    redirect_to :action => "index", :display_name => entry.user.display_name
  end

  def unhide
    entry = DiaryEntry.find(params[:id])
    entry.update(:visible => true)
    redirect_to :action => "index", :display_name => entry.user.display_name
  end

  def hidecomment
    comment = DiaryComment.find(params[:comment])
    comment.update(:visible => false)
    redirect_to diary_entry_path(comment.diary_entry.user, comment.diary_entry)
  end

  def unhidecomment
    comment = DiaryComment.find(params[:comment])
    comment.update(:visible => true)
    redirect_to diary_entry_path(comment.diary_entry.user, comment.diary_entry)
  end

  def comments
    @title = t ".title", :user => @user.display_name

    comments = DiaryComment.where(:user => @user)
    comments = comments.visible unless can? :unhidecomment, DiaryEntry

    @params = params.permit(:display_name, :before, :after)

    @comments, @newer_comments_id, @older_comments_id = get_page_items(comments, [:user])
  end

  private

  ##
  # return permitted diary entry parameters
  def entry_params
    params.require(:diary_entry).permit(:title, :body, :language_code, :latitude, :longitude)
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new.permit(:title, :body, :language_code, :latitude, :longitude)
  end

  ##
  # return permitted diary comment parameters
  def comment_params
    params.require(:diary_comment).permit(:body)
  end

  ##
  # decide on a location for the diary entry map
  def set_map_location
    if @diary_entry.latitude && @diary_entry.longitude
      @lon = @diary_entry.longitude
      @lat = @diary_entry.latitude
      @zoom = 12
    elsif !current_user.home_location?
      @lon = params[:lon] || -0.1
      @lat = params[:lat] || 51.5
      @zoom = params[:zoom] || 4
    else
      @lon = current_user.home_lon
      @lat = current_user.home_lat
      @zoom = 12
    end
  end

  def get_page_items(items, includes)
    id_column = "#{items.table_name}.id"
    page_items = if params[:before]
                   items.where("#{id_column} < ?", params[:before]).order(:id => :desc)
                 elsif params[:after]
                   items.where("#{id_column} > ?", params[:after]).order(:id => :asc)
                 else
                   items.order(:id => :desc)
                 end

    page_items = page_items.limit(20)
    page_items = page_items.includes(includes)
    page_items = page_items.sort.reverse

    newer_items_id = page_items.first.id if page_items.count.positive? && items.exists?(["#{id_column} > ?", page_items.first.id])
    older_items_id = page_items.last.id if page_items.count.positive? && items.exists?(["#{id_column} < ?", page_items.last.id])

    [page_items, newer_items_id, older_items_id]
  end
end
