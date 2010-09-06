class DiaryEntryController < ApplicationController
  layout 'site', :except => :rss

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:new, :edit, :comment, :hide, :hidecomment]
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:new, :edit]
  before_filter :require_administrator, :only => [:hide, :hidecomment]

  caches_action :list, :view, :layout => false
  caches_action :rss, :layout => true
  cache_sweeper :diary_sweeper, :only => [:new, :edit, :comment, :hide, :hidecomment], :unless => STATUS == :database_offline

  def new
    @title = t 'diary_entry.new.title'

    if params[:diary_entry]
      @diary_entry = DiaryEntry.new(params[:diary_entry])
      @diary_entry.user = @user

      if @diary_entry.save
        default_lang = @user.preferences.find(:first, :conditions => {:k => "diary.default_language"})
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
      default_lang = @user.preferences.find(:first, :conditions => {:k => "diary.default_language"})
      lang_code = default_lang ? default_lang.v : @user.preferred_language
      @diary_entry = DiaryEntry.new(:language_code => lang_code)
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
    @diary_comment = @entry.comments.build(params[:diary_comment])
    @diary_comment.user = @user
    if @diary_comment.save
      if @diary_comment.user != @entry.user
        Notifier::deliver_diary_comment_notification(@diary_comment)
      end

      redirect_to :controller => 'diary_entry', :action => 'view', :display_name => @entry.user.display_name, :id => @entry.id
    else
      render :action => 'view'
    end
  end

  def list
    if params[:display_name]
      @this_user = User.find_by_display_name(params[:display_name], :conditions => { :status => ["active", "confirmed"] })

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
        @title = t'diary_entry.no_such_user.title'
        @not_found_user = params[:display_name]

        render :action => 'no_such_user', :status => :not_found
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
    request.format = :rss

    if params[:display_name]
      user = User.find_by_display_name(params[:display_name], :conditions => { :status => ["active", "confirmed"] })

      if user
        @entries = DiaryEntry.find(:all, 
                                   :conditions => { 
                                     :user_id => user.id,
                                     :visible => true 
                                   },
                                   :order => 'created_at DESC', 
                                   :limit => 20)
        @title = I18n.t('diary_entry.feed.user.title', :user => user.display_name)
        @description = I18n.t('diary_entry.feed.user.description', :user => user.display_name)
        @link = "http://#{SERVER_URL}/user/#{user.display_name}/diary"
      else
        render :nothing => true, :status => :not_found
      end
    elsif params[:language]
      @entries = DiaryEntry.find(:all, :include => :user,
                                 :conditions => {
                                   :users => { :status => ["active", "confirmed"] },
                                   :visible => true,
                                   :language_code => params[:language]
                                 },
                                 :order => 'created_at DESC', 
                                 :limit => 20)
      @title = I18n.t('diary_entry.feed.language.title', :language_name => Language.find(params[:language]).english_name)
      @description = I18n.t('diary_entry.feed.language.description', :language_name => Language.find(params[:language]).english_name)
      @link = "http://#{SERVER_URL}/diary/#{params[:language]}"
    else
      @entries = DiaryEntry.find(:all, :include => :user,
                                 :conditions => {
                                   :users => { :status => ["active", "confirmed"] },
                                   :visible => true
                                 },
                                 :order => 'created_at DESC', 
                                 :limit => 20)
      @title = I18n.t('diary_entry.feed.all.title')
      @description = I18n.t('diary_entry.feed.all.description')
      @link = "http://#{SERVER_URL}/diary"
    end
  end

  def view
    user = User.find_by_display_name(params[:display_name], :conditions => { :status => ["active", "confirmed"] })

    if user
      @entry = DiaryEntry.find(:first, :conditions => {
                                 :id => params[:id],
                                 :user_id => user.id,
                                 :visible => true
                               })
      if @entry
        @title = t 'diary_entry.view.title', :user => params[:display_name], :title => @entry.title
      else
        @title = t 'diary_entry.no_such_entry.title', :id => params[:id]
        render :action => 'no_such_entry', :status => :not_found
      end
    else
      @not_found_user = params[:display_name]

      render :action => 'no_such_user', :status => :not_found
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
end
