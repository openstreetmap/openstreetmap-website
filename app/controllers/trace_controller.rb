class TraceController < ApplicationController
  before_filter :authorize_web  
  layout 'site'

  def list
    @traces = Trace.find(:all)
  end

  def mine
    @traces = Trace.find(:all, :conditions => ['user_id = ?', @user.id])
  end

  def create
    filename = "/tmp/#{rand}"

    File.open(filename, "w") { |f| f.write(@params['trace']['gpx_file'].read) }
    @params['trace']['name'] = @params['trace']['gpx_file'].original_filename.gsub(/[^a-zA-Z0-9.]/, '_') # This makes sure filenames are sane
    #@params['trace']['data'] = @params['trace']['gpx_file'].read
#    @params['trace']['mime_type'] = @params['trace']['gpx_file'].content_type.chomp
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
end
