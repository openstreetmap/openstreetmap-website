class MapBugsController < ApplicationController

  before_filter :check_api_readable
  before_filter :authorize_web, :only => [:add_bug, :close_bug, :edit_bug]
  before_filter :check_api_writable, :only => [:add_bug, :close_bug, :edit_bug]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  def get_bugs

	raise OSM::APIBadUserInput.new("No l was given") unless params['l']
	raise OSM::APIBadUserInput.new("No r was given") unless params['r']
	raise OSM::APIBadUserInput.new("No b was given") unless params['b']
	raise OSM::APIBadUserInput.new("No t was given") unless params['t']

	min_lon = params['l'].to_f
	max_lon = params['r'].to_f
	min_lat = params['b'].to_f
	max_lat = params['t'].to_f
	
	# check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(min_lon, min_lat, max_lon, max_lat)
    rescue Exception => err
      report_error(err.message)
      return
    end

	@bugs = MapBug.find_by_area(min_lat, min_lon, max_lat, max_lon, :order => "last_changed DESC", :limit => 100, :conditions => "status != 'hidden'")

	respond_to do |format|
	  format.html {render :template => 'map_bugs/get_bugs.js', :content_type => "text/javascript"}
	  format.rss {render :template => 'map_bugs/get_bugs.rss'}
	  format.js
	  format.xml {render :template => 'map_bugs/get_bugs.xml'}
	  #format.gpx {render :text => "Rendering GPX"}
	end
  end

  def add_bug
	raise OSM::APIBadUserInput.new("No lat was given") unless params['lat']
	raise OSM::APIBadUserInput.new("No lon was given") unless params['lon']
	raise OSM::APIBadUserInput.new("No text was given") unless params['text']

	lon = params['lon'].to_f
	lat = params['lat'].to_f
	comment = params['text']

    bug = MapBug.create_bug(lat, lon)
	bug.save;
	add_comment(bug, comment);
 
	render_ok
  end

  def edit_bug
	raise OSM::APIBadUserInput.new("No id was given") unless params['id']
	raise OSM::APIBadUserInput.new("No text was given") unless params['text']

	id = params['id'].to_i

	bug = MapBug.find_by_id(id);

	bug_comment = add_comment(bug, params['text']);

	render_ok
  end

  def close_bug
	raise OSM::APIBadUserInput.new("No id was given") unless params['id']
	
	id = params['id'].to_i

	bug = MapBug.find_by_id(id);
	bug.close_bug;

	render_ok
  end 

  def render_ok
	output_js = :false
	output_js = :true if params['format'] == "js"

	if output_js == :true
	  render :text => "osbResponse();", :content_type => "text/javascript" 
	else
	  render :text => "ok\n", :content_type => "text/html" 
	end
	
  end

  def rss
	request.format = :rss
	get_bugs
  end

  def gpx_bugs
	request.format = :xml
	get_bugs
  end

  def add_comment(bug, comment) 
    t = Time.now.getutc 
    bug_comment = bug.map_bug_comment.create(:date_created => t, :visible => true, :comment => comment);  
    if @user  
      bug_comment.commenter_id = @user.id
	  bug_comment.commenter_name = @user.display_name
    else  
      bug_comment.commenter_ip = request.remote_ip
	  bug_comment.commenter_name = "anonymous (a)"
    end
    bug_comment.save; 
    bug.last_changed = t 
    bug.save 
  end

end
