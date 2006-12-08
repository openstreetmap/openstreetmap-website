class TraceController < ApplicationController
  before_filter :authorize_web  
  layout 'site'

  def list
    @page = params[:page].to_i

    opt = Hash.new
    opt[:conditions] = ['public = true']
    opt[:order] = 'timestamp DESC'
    opt[:limit] = 20

    if @page > 0
      opt[:offset => 20*@page]
    end

    if params[:tag]
      
    end

    @traces = Trace.find(:all , opt)
  end

  def view
    @trace = Trace.find(params[:id])
    unless @trace.public
      if @user
        render :nothing, :status => 401 if @trace.user.id != @user.id
      end
    end
  end

  def create
    filename = "/tmp/#{rand}"

    File.open(filename, "w") { |f| f.write(@params['trace']['gpx_file'].read) }
    @params['trace']['name'] = @params['trace']['gpx_file'].original_filename.gsub(/[^a-zA-Z0-9.]/, '_') # This makes sure filenames are sane
    @params['trace'].delete('gpx_file') # let's remove the field from the hash, because there's no such field in the DB anyway.
    @trace = Trace.new(@params['trace'])
    @trace.inserted = false
    @trace.user_id = @user.id
    @trace.timestamp = Time.now
    if @trace.save
      logger.info("id is #{@trace.id}")
      `mv #{filename} /tmp/#{@trace.id}.gpx`
      flash[:notice] = "Your GPX file has been uploaded and is awaiting insertion in to the database. This will usually happen within half an hour, and an email will be sent to you on completion."
    end

    redirect_to :action => 'mine'
  end

  def georss
    traces = Trace.find(:all, :conditions => ['public = true'], :order => 'timestamp DESC', :limit => 20)

    rss = OSM::GeoRSS.new

    #def add(latitude=0, longitude=0, title_text='dummy title', url='http://www.example.com/', description_text='dummy description', timestamp=Time.now)
    traces.each do |trace|
      rss.add(trace.latitude, trace.longitude, trace.name, url_for({:controller => 'trace', :action => 'view', :id => trace.id, :display_name => trace.user.display_name}), "<img src='#{url_for({:controller => 'trace', :action => 'icon', :id => trace.id, :user_login => trace.user.display_name})}'> GPX file with #{trace.size} points from #{trace.user.display_name}", trace.timestamp)
    end

    response.headers["Content-Type"] = 'application/xml+rss'

    render :text => rss.to_s
  end

  def picture
    trace = Trace.find(params[:id])
    send_data(trace.large_picture, :filename => "#{trace.id}.gif", :type => 'image/png', :disposition => 'inline') if trace.public
  end

  def icon
    trace = Trace.find(params[:id])
    send_data(trace.icon_picture, :filename => "#{trace.id}.gif", :type => 'image/gif', :disposition => 'inline') if trace.public
  end
end
