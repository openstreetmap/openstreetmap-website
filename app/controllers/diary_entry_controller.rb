class DiaryEntryController < ApplicationController
  layout 'site'
  
  before_filter :authorize_web
  before_filter :require_user, :only => [:new]

  def new
    @title = 'new diary entry'
    if params[:diary_entry]     
      @entry = DiaryEntry.new(params[:diary_entry])
      @entry.user = @user
      if @entry.save 
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
      @this_user = User.find_by_display_name(params[:display_name])
      @entries=DiaryEntry.find(:all, :conditions => ['user_id = ?', @this_user.id], :order => 'created_at DESC', :limit => 20)
      rss = OSM::GeoRSS.new("OpenStreetMap diary entries for #{@this_user.display_name}", "Recent OpenStreetmap diary entries from #{@this_user.display_name}", "http://www.openstreetmap.org/user/#{@this_user.display_name}/diary") 
    else
      @entries=DiaryEntry.find(:all, :order => 'created_at DESC', :limit => 20)
      rss = OSM::GeoRSS.new('OpenStreetMap diary entries', 'Recent diary entries from users of OpenStreetMap', 'http://www.openstreetmap.org/diary') 
    end

    @entries.each do |entry|
      # add geodata here
      latitude = nil
      longitude = nil
      rss.add(latitude, longitude, entry.title, entry.user.display_name, url_for({:controller => 'diary_entry', :action => 'list', :id => entry.id, :display_name => entry.user.display_name}), entry.body, entry.created_at)
    end

    render :text => rss.to_s, :content_type => "application/rss+xml"
  end

end
