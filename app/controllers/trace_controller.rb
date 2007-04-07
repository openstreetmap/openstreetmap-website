class TraceController < ApplicationController
  before_filter :authorize_web  
  before_filter :authorize, :only => [:api_details, :api_data, :api_create]
  layout 'site'
  
  # Counts and selects pages of GPX traces for various criteria (by user, tags, public etc.).
  #  target_user - if set, specifies the user to fetch traces for.  if not set will fetch all traces
  #  paging_action - the action that will be linked back to from view
  def list (target_user = nil, paging_action = 'list')
    @traces_per_page = 20
    page_index = params[:page] ? params[:page].to_i - 1 : 0 # nice 1-based page -> 0-based page index

    # from display name, pick up user id if one user's traces only
    display_name = params[:display_name]
    if target_user.nil? and display_name and display_name != ''
      target_user = User.find(:first, :conditions => [ "display_name = ?", display_name])
    end

    opt = Hash.new
    opt[:include] = [:user, :tags] # load users and tags from db at same time as traces

    # four main cases:
    # 1 - all traces, logged in = all public traces + all user's (i.e + all mine)
    # 2 - all traces, not logged in = all public traces
    # 3 - user's traces, logged in as same user = all user's traces 
    # 4 - user's traces, not logged in as that user = all user's public traces
    if target_user.nil? # all traces
      if @user
        conditions = ["(public = 1 OR user_id = ?)", @user.id] #1
      else
        conditions  = ["public = 1"] #2
      end
    else
      if @user and @user.id == target_user.id
        conditions = ["user_id = ?", @user.id] #3 (check vs user id, so no join + can't pick up non-public traces by changing name)
      else
        conditions = ["public = 1 AND user_id = ?", target_user.id] #4
      end
    end
    conditions[0] += " AND users.display_name != ''" # users need to set display name before traces will be exposed
    
    opt[:order] = 'timestamp DESC'
    if params[:tag]
      @tag = params[:tag]
      conditions[0] += " AND gpx_file_tags.tag = ?"
      conditions << @tag;
    end
    
    opt[:conditions] = conditions

    # count traces using all options except limit
    @max_trace = Trace.count(opt)
    @max_page = Integer((@max_trace + 1) / @traces_per_page) 
    
    # last step before fetch - add paging options
    opt[:limit] = @traces_per_page
    if page_index > 0
      opt[:offset] = @traces_per_page * page_index
    end

    @traces = Trace.find(:all , opt)
    
    # put together SET of tags across traces, for related links
    tagset = Hash.new
    if @traces
      @traces.each do |trace|
        trace.tags.reload if params[:tag] # if searched by tag, ActiveRecord won't bring back other tags, so do explicitly here
        trace.tags.each do |tag|
          tagset[tag.tag] = tag.tag
        end
      end
    end
    
    # final helper vars for view
    @display_name = display_name
    @all_tags = tagset.values
    @paging_action = paging_action # the action that paging requests should route back to, e.g. 'list' or 'mine'
    @page = page_index + 1 # nice 1-based external page numbers
  end

  def mine
    if @user
      list(@user, 'mine') unless @user.nil?
    else
      redirect_to :controller => 'user', :action => 'login'
    end
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
    @params['trace'].delete('gpx_file') # remove the field from the hash, because there's no such field in the DB
    @trace = Trace.new(@params['trace'])
    @trace.inserted = false
    @trace.user = @user
    @trace.timestamp = Time.now

    if @trace.save
      saved_filename = "/tmp/#{@trace.id}.gpx"
      File.rename(filename, saved_filename)

      logger.info("id is #{@trace.id}")
      flash[:notice] = "Your GPX file has been uploaded and is awaiting insertion in to the database. This will usually happen within half an hour, and an email will be sent to you on completion."
      redirect_to :action => 'mine'
    else
      # fixme throw an error here
      # render :action => 'mine'
    end
  end

  def data
    trace = Trace.find(params[:id])
    if trace.public? or (@user and @user == trace.user)
      send_data(File.open("/tmp/#{trace.id}.gpx",'r').read , :filename => "#{trace.id}.gpx", :type => 'text/plain', :disposition => 'inline')
    end
  end

  def make_public
    trace = Trace.find(params[:id])
    if @user and trace.user == @user and !trace.public
      trace.public = true
      trace.save
      flash[:notice] = 'Track made public'
      redirect_to :controller => 'trace', :action => 'view', :id => params[:id]
    end
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
    send_data(trace.large_picture, :filename => "#{trace.id}.gif", :type => 'image/gif', :disposition => 'inline') if trace.public? or (@user and @user == trace.user)
  end

  def icon
    trace = Trace.find(params[:id])
    send_data(trace.icon_picture, :filename => "#{trace.id}_icon.gif", :type => 'image/gif', :disposition => 'inline') if trace.public? or (@user and @user == trace.user)
  end

  def api_details
    trace = Trace.find(params[:id])
    doc = OSM::API.new.get_xml_doc
    doc.root << trace.to_xml_node() if trace.public? or trace.user == @user
    render :text => doc.to_s
  end

  def api_data
    render :action => 'data'
  end

  def api_create
    #FIXME merge this code with create as they're pretty similar?
    
    filename = "/tmp/#{rand}"
    File.open(filename, "w") { |f| f.write(request.raw_post) }
    @params['trace'] = {}
    @params['trace']['name'] = params[:filename]
    @params['trace']['tagstring'] = params[:tags]
    @params['trace']['description'] = params[:description]
    @trace = Trace.new(@params['trace'])
    @trace.inserted = false
    @trace.user = @user
    @trace.timestamp = Time.now

    if @trace.save
      saved_filename = "/tmp/#{@trace.id}.gpx"
      File.rename(filename, saved_filename)
      logger.info("id is #{@trace.id}")
      flash[:notice] = "Your GPX file has been uploaded and is awaiting insertion in to the database. This will usually happen within half an hour, and an email will be sent to you on completion."
      render :nothing => true
    else
      render :nothing => true, :status => 400 # er FIXME what fricking code to return?
    end

  end
end
