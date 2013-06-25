class TraceController < ApplicationController
  layout 'site'

  skip_before_filter :verify_authenticity_token, :only => [:api_create, :api_read, :api_update, :api_delete, :api_data]
  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:mine, :create, :edit, :delete]
  before_filter :authorize, :only => [:api_create, :api_read, :api_update, :api_delete, :api_data]
  before_filter :check_database_readable, :except => [:api_read, :api_data]
  before_filter :check_database_writable, :only => [:create, :edit, :delete, :api_create, :api_update, :api_delete]
  before_filter :check_api_readable, :only => [:api_read, :api_data]
  before_filter :check_api_writable, :only => [:api_create, :api_update, :api_delete]
  before_filter :require_allow_read_gpx, :only => [:api_read, :api_data]
  before_filter :require_allow_write_gpx, :only => [:api_create, :api_update, :api_delete]
  before_filter :offline_warning, :only => [:mine, :view]
  before_filter :offline_redirect, :only => [:create, :edit, :delete, :data, :api_create, :api_delete, :api_data]
  around_filter :api_call_handle_error, :only => [:api_create, :api_read, :api_update, :api_delete, :api_data]

  # Counts and selects pages of GPX traces for various criteria (by user, tags, public etc.).
  #  target_user - if set, specifies the user to fetch traces for.  if not set will fetch all traces
  def list
    # from display name, pick up user id if one user's traces only
    display_name = params[:display_name]
    if !display_name.blank?
      target_user = User.active.where(:display_name => display_name).first
      if target_user.nil?
        render_unknown_user display_name
        return
      end
    end

    # set title
    if target_user.nil?
      @title = t 'trace.list.public_traces'
    elsif @user and @user == target_user
      @title = t 'trace.list.your_traces'
    else
      @title = t 'trace.list.public_traces_from', :user => target_user.display_name
    end

    @title += t 'trace.list.tagged_with', :tags => params[:tag] if params[:tag]

    # four main cases:
    # 1 - all traces, logged in = all public traces + all user's (i.e + all mine)
    # 2 - all traces, not logged in = all public traces
    # 3 - user's traces, logged in as same user = all user's traces
    # 4 - user's traces, not logged in as that user = all user's public traces
    if target_user.nil? # all traces
      if @user
        @traces = Trace.visible_to(@user) #1
      else
        @traces = Trace.public #2
      end
    else
      if @user and @user == target_user
        @traces = @user.traces #3 (check vs user id, so no join + can't pick up non-public traces by changing name)
      else
        @traces = target_user.traces.public #4
      end
    end

    if params[:tag]
      @traces = @traces.tagged(params[:tag])
    end

    @page = (params[:page] || 1).to_i
    @page_size = 20

    @traces = @traces.visible
    @traces = @traces.order("timestamp DESC")
    @traces = @traces.offset((@page - 1) * @page_size)
    @traces = @traces.limit(@page_size)
    @traces = @traces.includes(:user, :tags)

    # put together SET of tags across traces, for related links
    tagset = Hash.new
    @traces.each do |trace|
      trace.tags.reload if params[:tag] # if searched by tag, ActiveRecord won't bring back other tags, so do explicitly here
      trace.tags.each do |tag|
        tagset[tag.tag] = tag.tag
      end
    end

    # final helper vars for view
    @target_user = target_user
    @display_name = target_user.display_name if target_user
    @all_tags = tagset.values
  end

  def mine
    redirect_to :action => :list, :display_name => @user.display_name
  end

  def view
    @trace = Trace.find(params[:id])

    if @trace and @trace.visible? and
       (@trace.public? or @trace.user == @user)
      @title = t 'trace.view.title', :name => @trace.name
    else
      flash[:error] = t 'trace.view.trace_not_found'
      redirect_to :controller => 'trace', :action => 'list'
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = t 'trace.view.trace_not_found'
    redirect_to :controller => 'trace', :action => 'list'
  end

  def create
    if params[:trace]
      logger.info(params[:trace][:gpx_file].class.name)

      if params[:trace][:gpx_file].respond_to?(:read)
        begin
          do_create(params[:trace][:gpx_file], params[:trace][:tagstring],
                    params[:trace][:description], params[:trace][:visibility])
        rescue => ex
          logger.debug ex
        end

        if @trace.id
          logger.info("id is #{@trace.id}")
          flash[:notice] = t 'trace.create.trace_uploaded'

          if @user.traces.count(:conditions => { :inserted => false }) > 4
            flash[:warning] = t 'trace.trace_header.traces_waiting', :count => @user.traces.count(:conditions => { :inserted => false })
          end

          redirect_to :action => :list, :display_name => @user.display_name
        end
      else
        @trace = Trace.new({:name => "Dummy",
                            :tagstring => params[:trace][:tagstring],
                            :description => params[:trace][:description],
                            :visibility => params[:trace][:visibility],
                            :inserted => false, :user => @user,
                            :timestamp => Time.now.getutc})
        @trace.valid?
        @trace.errors.add(:gpx_file, "can't be blank")
      end
    else
      @trace = Trace.new({:visibility => default_visibility}, :without_protection => true)
    end

    @title = t 'trace.create.upload_trace'
  end

  def data
    trace = Trace.find(params[:id])

    if trace.visible? and (trace.public? or (@user and @user == trace.user))
      if Acl.no_trace_download(request.remote_ip)
        render :nothing => true, :status => :forbidden
      elsif request.format == Mime::XML
        send_file(trace.xml_file, :filename => "#{trace.id}.xml", :type => Mime::XML.to_s, :disposition => 'attachment')
      else
        send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => 'attachment')
      end
    else
      render :nothing => true, :status => :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def edit
    @trace = Trace.find(params[:id])

    if @user and @trace.user == @user
      @title = t 'trace.edit.title', :name => @trace.name
      if params[:trace]
        @trace.description = params[:trace][:description]
        @trace.tagstring = params[:trace][:tagstring]
        @trace.visibility = params[:trace][:visibility]
        if @trace.save
          redirect_to :action => 'view', :display_name => @user.display_name
        end
      end
    else
      render :nothing => true, :status => :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def delete
    trace = Trace.find(params[:id])

    if @user and trace.user == @user
      if trace.visible?
        trace.visible = false
        trace.save
        flash[:notice] = t 'trace.delete.scheduled_for_deletion'
        redirect_to :action => :list, :display_name => @user.display_name
      else
        render :nothing => true, :status => :not_found
      end
    else
      render :nothing => true, :status => :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def georss
    traces = Trace.public.visible

    if params[:display_name]
      traces = traces.joins(:user).where(:users => {:display_name => params[:display_name]})
    end

    if params[:tag]
      traces = traces.tagged(params[:tag])
    end

    traces = traces.order("timestamp DESC")
    traces = traces.limit(20)
    traces = traces.includes(:user)

    rss = OSM::GeoRSS.new

    traces.each do |trace|
      rss.add(trace.latitude, trace.longitude, trace.name, trace.user.display_name, url_for({:controller => 'trace', :action => 'view', :id => trace.id, :display_name => trace.user.display_name}), "<img src='#{url_for({:controller => 'trace', :action => 'icon', :id => trace.id, :display_name => trace.user.display_name})}'> GPX file with #{trace.size} points from #{trace.user.display_name}", trace.timestamp)
    end

    render :text => rss.to_s, :content_type => "application/rss+xml"
  end

  def picture
    trace = Trace.find(params[:id])

    if trace.inserted?
      if trace.public? or (@user and @user == trace.user)
        expires_in 7.days, :private => !trace.public?, :public => trace.public?
        send_file(trace.large_picture_name, :filename => "#{trace.id}.gif", :type => 'image/gif', :disposition => 'inline')
      else
        render :nothing => true, :status => :forbidden
      end
    else
      render :nothing => true, :status => :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def icon
    trace = Trace.find(params[:id])

    if trace.inserted?
      if trace.public? or (@user and @user == trace.user)
        expires_in 7.days, :private => !trace.public?, :public => trace.public?
        send_file(trace.icon_picture_name, :filename => "#{trace.id}_icon.gif", :type => 'image/gif', :disposition => 'inline')
      else
        render :nothing => true, :status => :forbidden
      end
    else
      render :nothing => true, :status => :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def api_read
    trace = Trace.visible.find(params[:id])

    if trace.public? or trace.user == @user
      render :text => trace.to_xml.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :forbidden
    end
  end

  def api_update
    trace = Trace.visible.find(params[:id])

    if trace.user == @user
      new_trace = Trace.from_xml(request.raw_post)

      unless new_trace and new_trace.id == trace.id
        raise OSM::APIBadUserInput.new("The id in the url (#{trace.id}) is not the same as provided in the xml (#{new_trace.id})")
      end

      trace.description = new_trace.description
      trace.tags = new_trace.tags
      trace.visibility = new_trace.visibility
      trace.save!

      render :nothing => true, :status => :ok
    else
      render :nothing => true, :status => :forbidden
    end
  end

  def api_delete
    trace = Trace.visible.find(params[:id])

    if trace.user == @user
      trace.visible = false
      trace.save!

      render :nothing => true, :status => :ok
    else
      render :nothing => true, :status => :forbidden
    end
  end

  def api_data
    trace = Trace.find(params[:id])

    if trace.public? or trace.user == @user
      if request.format == Mime::XML
        send_file(trace.xml_file, :filename => "#{trace.id}.xml", :type => Mime::XML.to_s, :disposition => 'attachment')
      else
        send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => 'attachment')
      end
    else
      render :nothing => true, :status => :forbidden
    end
  end

  def api_create
    tags = params[:tags] || ""
    description = params[:description] || ""
    visibility = params[:visibility]

    if visibility.nil?
      if params[:public] && params[:public].to_i.nonzero?
        visibility = "public"
      else
        visibility = "private"
      end
    end

    if params[:file].respond_to?(:read)
      do_create(params[:file], tags, description, visibility)

      if @trace.id
        render :text => @trace.id.to_s, :content_type => "text/plain"
      elsif @trace.valid?
        render :nothing => true, :status => :internal_server_error
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :bad_request
    end
  end

private

  def do_create(file, tags, description, visibility)
    # Sanitise the user's filename
    name = file.original_filename.gsub(/[^a-zA-Z0-9.]/, '_')

    # Get a temporary filename...
    filename = "/tmp/#{rand}"

    # ...and save the uploaded file to that location
    File.open(filename, "wb") { |f| f.write(file.read) }

    # Create the trace object, falsely marked as already
    # inserted to stop the import daemon trying to load it
    @trace = Trace.new({
      :name => name,
      :tagstring => tags,
      :description => description,
      :visibility => visibility,
      :inserted => true,
      :user => @user,
      :timestamp => Time.now.getutc
    }, :without_protection => true)

    Trace.transaction do
      begin
        # Save the trace object
        @trace.save!

        # Rename the temporary file to the final name
        FileUtils.mv(filename, @trace.trace_name)
      rescue Exception => ex
        # Remove the file as we have failed to update the database
        FileUtils.rm_f(filename)

        # Pass the exception on
        raise
      end

      begin
        # Clear the inserted flag to make the import daemon load the trace
        @trace.inserted = false
        @trace.save!
      rescue Exception => ex
        # Remove the file as we have failed to update the database
        FileUtils.rm_f(@trace.trace_name)

        # Pass the exception on
        raise
      end
    end

    # Finally save the user's preferred privacy level
    if pref = @user.preferences.where(:k => "gps.trace.visibility").first
      pref.v = visibility
      pref.save
    else
      @user.preferences.create(:k => "gps.trace.visibility", :v => visibility)
    end

  end

  def offline_warning
    flash.now[:warning] = t 'trace.offline_warning.message' if STATUS == :gpx_offline
  end

  def offline_redirect
    redirect_to :action => :offline if STATUS == :gpx_offline
  end

  def default_visibility
    visibility = @user.preferences.where(:k => "gps.trace.visibility").first

    if visibility
      visibility.v
    elsif @user.preferences.where(:k => "gps.trace.public", :v => "default").first.nil?
      "private"
    else
      "public"
    end
  end

end
