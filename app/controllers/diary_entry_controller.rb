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
        redirect_to :controller => 'user', :action => 'diary', :display_name => @user.display_name 
      end
    end
  end
  
  def list
    @title = 'recent diary entries'
    @entries=DiaryEntry.find(:all, :order => 'created_at DESC', :limit=>20)
  end

  def rss
    @entries=DiaryEntry.find(:all, :order => 'created_at DESC', :limit=>20)

    rss = OSM::GeoRSS.new('OpenStreetMap diary entries', 'Recent diary entries from users of OpenStreetMap', 'http://www.openstreetmap.org/diary') 

    @entries.each do |entry|
      # add geodata here
      latitude = nil
      longitude = nil
      rss.add(latitude, longitude, entry.title, url_for({:controller => 'user', :action => 'diary', :id => entry.id, :display_name => entry.user.display_name}), entry.body, entry.created_at)
    end

    response.headers["Content-Type"] = 'application/rss+xml'

    render :text => rss.to_s
  end

end
