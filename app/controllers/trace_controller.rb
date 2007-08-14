class TraceController < ApplicationController
  before_filter :authorize_web  
  before_filter :authorize, :only => [:api_details, :api_data, :api_create]
  layout 'site'
 
  # Counts and selects pages of GPX traces for various criteria (by user, tags, public etc.).
  #  target_user - if set, specifies the user to fetch traces for.  if not set will fetch all traces
  def list (target_user = nil)
    # from display name, pick up user id if one user's traces only
    display_name = params[:display_name]
    if target_user.nil? and !display_name.blank?
      @display_name = display_name
      target_user = User.find(:first, :conditions => [ "display_name = ?", display_name])
    end

    # set title
    if target_user.nil?
      @title = "public GPS traces"
    elsif target_user.id == @user.id
      @title = "your GPS traces"
    else
      @title = "public GPS traces from #{target_user.display_name}"
    end

    @title += " tagged with #{params[:tag]}" if params[:tag]

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
    opt[:per_page] = 20

    @trace_pages, @traces = paginate(:traces, opt)
    
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
  end

  def mine
    if @user
      list(@user) unless @user.nil?
    else
      redirect_to :controller => 'user', :action => 'login', :referer => request.request_uri
    end
  end

  def view
    @trace = Trace.find(params[:id])
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
    traces = Trace.find(:all, :conditions => ['public = true'], :order => 'timestamp DESC', :limit => 20)

    rss = OSM::GeoRSS.new

    #def add(latitude=0, longitude=0, title_text='dummy title', url='http://www.example.com/', description_text='dummy description', timestamp=Time.now)
    traces.each do |trace|
      rss.add(trace.latitude, trace.longitude, trace.name, url_for({:controller => 'trace', :action => 'view', :id => trace.id, :display_name => trace.user.display_name}), "<img src='#{url_for({:controller => 'trace', :action => 'icon', :id => trace.id, :user_login => trace.user.display_name})}'> GPX file with #{trace.size} points from #{trace.user.display_name}", trace.timestamp)
    end

    render :text => rss.to_s, :content_type => "application/rss+xml"
  end

  def picture
    begin
      trace = Trace.find(params[:id])

      if trace.public? or (@user and @user == trace.user)
        send_file(trace.large_picture_name, :filename => "#{trace.id}.gif", :type => 'image/gif', :disposition => 'inline')
      else
        render :nothing, :status => :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def icon
    begin
      trace = Trace.find(params[:id])

      if trace.public? or (@user and @user == trace.user)
        send_file(trace.icon_picture_name, :filename => "#{trace.id}_icon.gif", :type => 'image/gif', :disposition => 'inline')
      else
        render :nothing, :status => :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def api_details
    begin
      trace = Trace.find(params[:id])

      if trace.public? or trace.user == @user
        render :text => trace.to_xml.to_s, :content_type => "text/xml"
      else
        render :nothing => true, :status => :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def api_data
    render :action => 'data'
  end

  def api_create
    do_create(params[:filename], params[:tags], params[:description], true) do |f|
      f.write(request.raw_post)
    end

    if @trace.id
      render :nothing => true
    else
      render :nothing => true, :status => :internal_server_error
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
