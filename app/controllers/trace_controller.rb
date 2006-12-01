class TraceController < ApplicationController
  before_filter :authorize_web  
  layout 'site'

  def list
    @traces = Trace.find(:all)
  end

  def mine
    @traces = Trace.find(:all, :conditions => ['user_id = ?', @user.id])
  end

  def view
    @trace = Trace.find(params[:id])
    render :nothing, :status => 401 if @trace.user.id != @user.id
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

  def picture
    trace = Trace.find(params[:id])
    send_data(trace.large_picture, :filename => "#{trace.id}.gif", :type => 'image/png', :disposition => 'inline') if trace.public
  end

  def icon
    trace = Trace.find(params[:id])
    send_data(trace.icon_picture, :filename => "#{trace.id}.gif", :type => 'image/gif', :disposition => 'inline') if trace.public
  end

end
