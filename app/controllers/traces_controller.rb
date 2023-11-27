class TracesController < ApplicationController
  include UserMethods

  layout "site", :except => :georss

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable, :only => [:new, :create, :edit, :destroy]
  before_action :offline_warning, :only => [:mine, :show]
  before_action :offline_redirect, :only => [:new, :create, :edit, :destroy, :data]

  # Counts and selects pages of GPX traces for various criteria (by user, tags, public etc.).
  #  target_user - if set, specifies the user to fetch traces for.  if not set will fetch all traces
  def index
    # from display name, pick up user id if one user's traces only
    display_name = params[:display_name]
    if display_name.present?
      target_user = User.active.find_by(:display_name => display_name)
      if target_user.nil?
        render_unknown_user display_name
        return
      end
    end

    # set title
    @title = if target_user.nil?
               t ".public_traces"
             elsif current_user && current_user == target_user
               t ".my_gps_traces"
             else
               t ".public_traces_from", :user => target_user.display_name
             end

    @title += t ".tagged_with", :tags => params[:tag] if params[:tag]

    # four main cases:
    # 1 - all traces, logged in = all public traces + all user's (i.e + all mine)
    # 2 - all traces, not logged in = all public traces
    # 3 - user's traces, logged in as same user = all user's traces
    # 4 - user's traces, not logged in as that user = all user's public traces
    traces = if target_user.nil? # all traces
               if current_user
                 Trace.visible_to(current_user) # 1
               else
                 Trace.visible_to_all # 2
               end
             elsif current_user && current_user == target_user
               current_user.traces # 3 (check vs user id, so no join + can't pick up non-public traces by changing name)
             else
               target_user.traces.visible_to_all # 4
             end

    traces = traces.tagged(params[:tag]) if params[:tag]

    traces = traces.visible

    @params = params.permit(:display_name, :tag, :before, :after)

    @traces = if params[:before]
                traces.where("gpx_files.id < ?", params[:before]).order(:id => :desc)
              elsif params[:after]
                traces.where("gpx_files.id > ?", params[:after]).order(:id => :asc)
              else
                traces.order(:id => :desc)
              end

    @traces = @traces.limit(20)
    @traces = @traces.includes(:user, :tags)
    @traces = @traces.sort.reverse

    @newer_traces = @traces.count.positive? && traces.exists?(["gpx_files.id > ?", @traces.first.id])
    @older_traces = @traces.count.positive? && traces.exists?(["gpx_files.id < ?", @traces.last.id])

    # final helper vars for view
    @target_user = target_user
  end

  def show
    @trace = Trace.find(params[:id])

    if @trace&.visible? &&
       (@trace&.public? || @trace&.user == current_user)
      @title = t ".title", :name => @trace.name
    else
      flash[:error] = t ".trace_not_found"
      redirect_to :action => "index"
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = t ".trace_not_found"
    redirect_to :action => "index"
  end

  def new
    @title = t ".upload_trace"
    @trace = Trace.new(:visibility => default_visibility)
  end

  def edit
    @trace = Trace.find(params[:id])

    if !@trace.visible?
      head :not_found
    elsif current_user.nil? || @trace.user != current_user
      head :forbidden
    else
      @title = t ".title", :name => @trace.name
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def create
    @title = t ".upload_trace"

    logger.info(params[:trace][:gpx_file].class.name)

    if params[:trace][:gpx_file].respond_to?(:read)
      @trace = do_create(params[:trace][:gpx_file], params[:trace][:tagstring],
                         params[:trace][:description], params[:trace][:visibility])

      if @trace.id
        flash[:notice] = t ".trace_uploaded"
        flash[:warning] = t ".traces_waiting", :count => current_user.traces.where(:inserted => false).count if current_user.traces.where(:inserted => false).count > 4

        TraceImporterJob.perform_later(@trace)
        redirect_to :action => :index, :display_name => current_user.display_name
      else
        flash[:error] = t(".upload_failed") if @trace.valid?

        render :action => "new"
      end
    else
      @trace = Trace.new(:name => "Dummy",
                         :tagstring => params[:trace][:tagstring],
                         :description => params[:trace][:description],
                         :visibility => params[:trace][:visibility],
                         :inserted => false, :user => current_user,
                         :timestamp => Time.now.utc)
      @trace.valid?
      @trace.errors.add(:gpx_file, "can't be blank")

      render :action => "new"
    end
  end

  def update
    @trace = Trace.find(params[:id])

    if !@trace.visible?
      head :not_found
    elsif current_user.nil? || @trace.user != current_user
      head :forbidden
    elsif @trace.update(trace_params)
      flash[:notice] = t ".updated"
      redirect_to :action => "show", :display_name => current_user.display_name
    else
      @title = t ".title", :name => @trace.name
      render :action => "edit"
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def destroy
    trace = Trace.find(params[:id])

    if !trace.visible?
      head :not_found
    elsif current_user.nil? || (trace.user != current_user && !current_user.administrator? && !current_user.moderator?)
      head :forbidden
    else
      trace.visible = false
      trace.save
      flash[:notice] = t ".scheduled_for_deletion"
      TraceDestroyerJob.perform_later(trace)
      redirect_to :action => :index, :display_name => trace.user.display_name
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def mine
    redirect_to :action => :index, :display_name => current_user.display_name
  end

  def data
    trace = Trace.find(params[:id])

    if trace.visible? && (trace.public? || (current_user && current_user == trace.user))
      if Acl.no_trace_download(request.remote_ip)
        head :forbidden
      elsif request.format == Mime[:xml]
        send_data(trace.xml_file.read, :filename => "#{trace.id}.xml", :type => request.format.to_s, :disposition => "attachment")
      elsif request.format == Mime[:gpx]
        send_data(trace.xml_file.read, :filename => "#{trace.id}.gpx", :type => request.format.to_s, :disposition => "attachment")
      elsif trace.file.attached?
        redirect_to rails_blob_path(trace.file, :disposition => "attachment")
      else
        send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => "attachment")
      end
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def georss
    @traces = Trace.visible_to_all.visible

    @traces = @traces.joins(:user).where(:users => { :display_name => params[:display_name] }) if params[:display_name]

    @traces = @traces.tagged(params[:tag]) if params[:tag]
    @traces = @traces.order("timestamp DESC")
    @traces = @traces.limit(20)
    @traces = @traces.includes(:user)
  end

  def picture
    trace = Trace.find(params[:id])

    if trace.visible? && trace.inserted?
      if trace.public? || (current_user && current_user == trace.user)
        if trace.icon.attached?
          redirect_to rails_blob_path(trace.image, :disposition => "inline")
        else
          expires_in 7.days, :private => !trace.public?, :public => trace.public?
          send_file(trace.large_picture_name, :filename => "#{trace.id}.gif", :type => "image/gif", :disposition => "inline")
        end
      else
        head :forbidden
      end
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def icon
    trace = Trace.find(params[:id])

    if trace.visible? && trace.inserted?
      if trace.public? || (current_user && current_user == trace.user)
        if trace.icon.attached?
          redirect_to rails_blob_path(trace.icon, :disposition => "inline")
        else
          expires_in 7.days, :private => !trace.public?, :public => trace.public?
          send_file(trace.icon_picture_name, :filename => "#{trace.id}_icon.gif", :type => "image/gif", :disposition => "inline")
        end
      else
        head :forbidden
      end
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def do_create(file, tags, description, visibility)
    # Sanitise the user's filename
    name = file.original_filename.gsub(/[^a-zA-Z0-9.]/, "_")

    # Create the trace object
    trace = Trace.new(
      :name => name,
      :tagstring => tags,
      :description => description,
      :visibility => visibility,
      :inserted => false,
      :user => current_user,
      :timestamp => Time.now.utc,
      :file => file
    )

    # Save the trace object
    if trace.save
      # Finally save the user's preferred privacy level
      if pref = current_user.preferences.find_by(:k => "gps.trace.visibility")
        pref.v = visibility
        pref.save
      else
        current_user.preferences.create(:k => "gps.trace.visibility", :v => visibility)
      end
    end

    trace
  end

  def offline_warning
    flash.now[:warning] = t "traces.offline_warning.message" if Settings.status == "gpx_offline"
  end

  def offline_redirect
    render :action => :offline if Settings.status == "gpx_offline"
  end

  def default_visibility
    visibility = current_user.preferences.find_by(:k => "gps.trace.visibility")

    if visibility
      visibility.v
    elsif current_user.preferences.find_by(:k => "gps.trace.public", :v => "default").nil?
      "private"
    else
      "public"
    end
  end

  def trace_params
    params.require(:trace).permit(:description, :tagstring, :visibility)
  end
end
