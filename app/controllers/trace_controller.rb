class TraceController < ApplicationController
  before_filter :authorize_web  
  before_filter :authorize, :only => [:api_details, :api_data, :api_create]
  layout 'site'
 
  # Counts and selects pages of GPX traces for various criteria (by user, tags, public etc.).
  #  target_user - if set, specifies the user to fetch traces for.  if not set will fetch all traces
  def list(target_user = nil, action = "list")
    # from display name, pick up user id if one user's traces only
    display_name = params[:display_name]
    if target_user.nil? and !display_name.blank?
      target_user = User.find(:first, :conditions => [ "display_name = ?", display_name])
    end

    # set title
    if target_user.nil?
      @title = "Public GPS traces"
    elsif @user and @user.id == target_user.id
      @title = "Your GPS traces"
    else
      @title = "Public GPS traces from #{target_user.display_name}"
    end

    @title += " tagged with #{params[:tag]}" if params[:tag]

    # four main cases:
    # 1 - all traces, logged in = all public traces + all user's (i.e + all mine)
    # 2 - all traces, not logged in = all public traces
    # 3 - user's traces, logged in as same user = all user's traces 
    # 4 - user's traces, not logged in as that user = all user's public traces
    if target_user.nil? # all traces
      if @user
        conditions = ["(gpx_files.public = 1 OR gpx_files.user_id = ?)", @user.id] #1
      else
        conditions  = ["gpx_files.public = 1"] #2
      end
    else
      if @user and @user.id == target_user.id
        conditions = ["gpx_files.user_id = ?", @user.id] #3 (check vs user id, so no join + can't pick up non-public traces by changing name)
      else
        conditions = ["gpx_files.public = 1 AND gpx_files.user_id = ?", target_user.id] #4
      end
    end
    
    if params[:tag]
      @tag = params[:tag]
      conditions[0] += " AND EXISTS (SELECT * FROM gpx_file_tags AS gft WHERE gft.gpx_id = gpx_files.id AND gft.tag = ?)"
      conditions << @tag
    end
    
    @trace_pages, @traces = paginate(:traces,
                                     :include => [:user, :tags],
                                     :conditions => conditions,
                                     :order => "gpx_files.timestamp DESC",
                                     :per_page => 20)

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
    @action = action
    @display_name = target_user.display_name if target_user
    @all_tags = tagset.values
  end

  def mine
    if @user
      list(@user, "mine") unless @user.nil?
    else
      redirect_to :controller => 'user', :action => 'login', :referer => request.request_uri
    end
  end

  def view
    @trace = Trace.find(params[:id])
    @title = "Viewing trace #{@trace.name}"
    unless @trace.public
      if @user
        render :nothing, :status => :forbidden if @trace.user.id != @user.id
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def create
    name = params[:trace][:gpx_file].original_filename.gsub(/[^a-zA-Z0-9.]/, '_') # This makes sure filenames are sane

    do_create(name, params[:trace][:tagstring], params[:trace][:description], params[:trace][:public]) do |f|
      f.write(params[:trace][:gpx_file].read)
    end

    if @trace.id
      logger.info("id is #{@trace.id}")
      flash[:notice] = "Your GPX file has been uploaded and is awaiting insertion in to the database. This will usually happen within half an hour, and an email will be sent to you on completion."

      redirect_to :action => 'mine'
    end
  end

  def data
    trace = Trace.find(params[:id])
    if trace and (trace.public? or (@user and @user == trace.user))
      send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => 'attachment')
    else
      render :nothing, :status => :not_found
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
    conditions = ["gpx_files.public = 1"]

    if params[:display_name]
      conditions[0] += " AND users.display_name = ?"
      conditions << params[:display_name]
    end
    
    if params[:tag]
      conditions[0] += " AND EXISTS (SELECT * FROM gpx_file_tags AS gft WHERE gft.gpx_id = gpx_files.id AND gft.tag = ?)"
      conditions << params[:tag]
    end

    traces = Trace.find(:all, :include => :user, :conditions => conditions, 
                        :order => "timestamp DESC", :limit => 20)

    rss = OSM::GeoRSS.new

    traces.each do |trace|
      rss.add(trace.latitude, trace.longitude, trace.name, trace.user.display_name, url_for({:controller => 'trace', :action => 'view', :id => trace.id, :display_name => trace.user.display_name}), "<img src='#{url_for({:controller => 'trace', :action => 'icon', :id => trace.id, :user_login => trace.user.display_name})}'> GPX file with #{trace.size} points from #{trace.user.display_name}", trace.timestamp)
    end

    render :text => rss.to_s, :content_type => "application/rss+xml"
  end

  def picture
    trace = Trace.find(params[:id])

    if trace.public? or (@user and @user == trace.user)
      send_file(trace.large_picture_name, :filename => "#{trace.id}.gif", :type => 'image/gif', :disposition => 'inline')
    else
      render :nothing, :status => :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def icon
    trace = Trace.find(params[:id])

    if trace.public? or (@user and @user == trace.user)
      send_file(trace.icon_picture_name, :filename => "#{trace.id}_icon.gif", :type => 'image/gif', :disposition => 'inline')
    else
      render :nothing, :status => :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def api_details
    trace = Trace.find(params[:id])

    if trace.public? or trace.user == @user
      render :text => trace.to_xml.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def api_data
    trace = Trace.find(params[:id])

    if trace.public? or trace.user == @user
      send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => 'attachment')
    else
      render :nothing => true, :status => :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def api_create
    if request.post?
      name = params[:file].original_filename.gsub(/[^a-zA-Z0-9.]/, '_') # This makes sure filenames are sane

      do_create(name, params[:tags], params[:description], params[:public]) do |f|
        f.write(request[:file].read)
      end

      if @trace.id
        render :text => @trace.id.to_s, :content_type => "text/plain"
      elsif @trace.valid?
        render :nothing => true, :status => :internal_server_error
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :method_not_allowed
    end
  end

private

  def do_create(name, tags, description, public)
    filename = "/tmp/#{rand}"

    File.open(filename, "w") { |f| yield f }

    @trace = Trace.new({:name => name, :tagstring => tags,
                        :description => description, :public => public})
    @trace.inserted = false
    @trace.user = @user
    @trace.timestamp = Time.now

    if @trace.save
      File.rename(filename, @trace.trace_name)
    else
      FileUtils.rm_f(filename)
    end
  end

end
