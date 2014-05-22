class ApplicationController < ActionController::Base
  include SessionPersistence

  protect_from_forgery

  before_filter :fetch_body

  def authorize_web
    if session[:user]
      @user = User.where(:id => session[:user]).where("status IN ('active', 'confirmed', 'suspended')").first

    if @user.status == "suspended"
        session.delete(:user)
        session_expires_automatically

        redirect_to :controller => "user", :action => "suspended"

        # don't allow access to any auth-requiring part of the site unless
        # the new CTs have been seen (and accept/decline chosen).
      elsif !@user.terms_seen and flash[:skip_terms].nil?
        flash[:notice] = t 'user.terms.you need to accept or decline'
        if params[:referer]
          redirect_to :controller => "user", :action => "terms", :referer => params[:referer]
        else
          redirect_to :controller => "user", :action => "terms", :referer => request.fullpath
        end
      end
    elsif session[:token]
      if @user = User.authenticate(:token => session[:token])
        session[:user] = @user.id
      end
    end
  rescue Exception => ex
    logger.info("Exception authorizing user: #{ex.to_s}")
    reset_session
    @user = nil
  end

  def require_user
    unless @user
      if request.get?
        redirect_to :controller => 'user', :action => 'login', :referer => request.fullpath
      else
        render :text => "", :status => :forbidden
      end
    end
  end

  def require_oauth
    @oauth = @user.access_token(OAUTH_KEY) if @user and defined? OAUTH_KEY
  end

  ##
  # requires the user to be logged in by the token or HTTP methods, or have an 
  # OAuth token with the right capability. this method is a bit of a pain to call 
  # directly, since it's cumbersome to call filters with arguments in rails. to
  # make it easier to read and write the code, there are some utility methods
  # below.
  def require_capability(cap)
    # when the current token is nil, it means the user logged in with a different
    # method, otherwise an OAuth token was used, which has to be checked.
    unless current_token.nil?
      unless current_token.read_attribute(cap)
        report_error "OAuth token doesn't have that capability.", :forbidden
        return false
      end
    end
  end

  ##
  # require the user to have cookies enabled in their browser
  def require_cookies
    if request.cookies["_osm_session"].to_s == ""
      if params[:cookie_test].nil?
        session[:cookie_test] = true
        redirect_to params.merge(:cookie_test => "true")
        return false
      else
        flash.now[:warning] = t 'application.require_cookies.cookies_needed'
      end
    else
      session.delete(:cookie_test)
    end
  end

  # Utility methods to make the controller filter methods easier to read and write.
  def require_allow_read_prefs
    require_capability(:allow_read_prefs)
  end
  def require_allow_write_prefs
    require_capability(:allow_write_prefs)
  end
  def require_allow_write_diary
    require_capability(:allow_write_diary)
  end
  def require_allow_write_api
    require_capability(:allow_write_api)

    if REQUIRE_TERMS_AGREED and @user.terms_agreed.nil?
      report_error "You must accept the contributor terms before you can edit.", :forbidden
      return false
    end
  end
  def require_allow_read_gpx
    require_capability(:allow_read_gpx)
  end
  def require_allow_write_gpx
    require_capability(:allow_write_gpx)
  end
  def require_allow_write_notes
    require_capability(:allow_write_notes)
  end

  ##
  # require that the user is a moderator, or fill out a helpful error message
  # and return them to the index for the controller this is wrapped from.
  def require_moderator
    unless @user.moderator?
      if request.get?
        flash[:error] = t('application.require_moderator.not_a_moderator')
        redirect_to :action => 'index'
      else
        render :text => "", :status => :forbidden
      end
    end
  end

  ##
  # sets up the @user object for use by other methods. this is mostly called
  # from the authorize method, but can be called elsewhere if authorisation
  # is optional.
  def setup_user_auth
    # try and setup using OAuth
    if not Authenticator.new(self, [:token]).allow?
      username, passwd = get_auth_data # parse from headers
      # authenticate per-scheme
      if username.nil?
        @user = nil # no authentication provided - perhaps first connect (client should retry after 401)
      elsif username == 'token'
        @user = User.authenticate(:token => passwd) # preferred - random token for user from db, passed in basic auth
      else
        @user = User.authenticate(:username => username, :password => passwd) # basic auth
      end
    end

    # have we identified the user?
    if @user
      # check if the user has been banned
      if @user.blocks.active.exists?
        # NOTE: need slightly more helpful message than this.
        report_error t('application.setup_user_auth.blocked'), :forbidden
      end

      # if the user hasn't seen the contributor terms then don't
      # allow editing - they have to go to the web site and see
      # (but can decline) the CTs to continue.
      if REQUIRE_TERMS_SEEN and not @user.terms_seen and flash[:skip_terms].nil?
        set_locale
        report_error t('application.setup_user_auth.need_to_see_terms'), :forbidden
      end
    end
  end

  def authorize(realm='Web Password', errormessage="Couldn't authenticate you") 
    # make the @user object from any auth sources we have
    setup_user_auth

    # handle authenticate pass/fail
    unless @user
      # no auth, the user does not exist or the password was wrong
      response.headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\"" 
      render :text => errormessage, :status => :unauthorized
      return false
    end 
  end 

  ##
  # to be used as a before_filter *after* authorize. this checks that
  # the user is a moderator and, if not, returns a forbidden error.
  #
  # NOTE: this isn't a very good way of doing it - it duplicates logic
  # from require_moderator - but what we really need to do is a fairly
  # drastic refactoring based on :format and respond_to? but not a 
  # good idea to do that in this branch.
  def authorize_moderator(errormessage="Access restricted to moderators") 
    # check user is a moderator
    unless @user.moderator?
      render :text => errormessage, :status => :forbidden
      return false
    end 
  end 

  def check_database_readable(need_api = false)
    if STATUS == :database_offline or (need_api and STATUS == :api_offline)
      redirect_to :controller => 'site', :action => 'offline'
    end
  end

  def check_database_writable(need_api = false)
    if STATUS == :database_offline or STATUS == :database_readonly or
       (need_api and (STATUS == :api_offline or STATUS == :api_readonly))
      redirect_to :controller => 'site', :action => 'offline'
    end
  end

  def check_api_readable
    if api_status == :offline
      report_error "Database offline for maintenance", :service_unavailable
      return false
    end
  end

  def check_api_writable
    unless api_status == :online
      report_error "Database offline for maintenance", :service_unavailable
      return false
    end
  end

  def database_status
    if STATUS == :database_offline
      :offline
    elsif STATUS == :database_readonly
      :readonly
    else 
      :online
    end
  end

  def api_status
    status = database_status
    if status == :online
      if STATUS == :api_offline
        status = :offline
      elsif STATUS == :api_readonly
        status = :readonly
      end
    end
    return status
  end

  def gpx_status
    status = database_status
    if status == :online
      status = :offline if STATUS == :gpx_offline
    end
    return status
  end

  def require_public_data
    unless @user.data_public?
      report_error "You must make your edits public to upload new data", :forbidden
      return false
    end
  end

  # Report and error to the user
  # (If anyone ever fixes Rails so it can set a http status "reason phrase",
  #  rather than only a status code and having the web engine make up a 
  #  phrase from that, we can also put the error message into the status
  #  message. For now, rails won't let us)
  def report_error(message, status = :bad_request)
    # Todo: some sort of escaping of problem characters in the message
    response.headers['Error'] = message

    if request.headers['X-Error-Format'] and
       request.headers['X-Error-Format'].downcase == "xml"
      result = OSM::API.new.get_xml_doc
      result.root.name = "osmError"
      result.root << (XML::Node.new("status") << "#{Rack::Utils.status_code(status)} #{Rack::Utils::HTTP_STATUS_CODES[status]}")
      result.root << (XML::Node.new("message") << message)

      render :text => result.to_s, :content_type => "text/xml"
    else
      render :text => message, :status => status, :content_type => "text/plain"
    end
  end
  
  def set_locale
    response.header['Vary'] = 'Accept-Language'

    if @user && !@user.languages.empty?
      http_accept_language.user_preferred_languages = @user.languages
      response.header['Vary'] = '*'
    end

    I18n.locale = select_locale

    if @user && @user.languages.empty? && !http_accept_language.user_preferred_languages.empty?
      @user.languages = http_accept_language.user_preferred_languages
      @user.save
    end

    response.headers['Content-Language'] = I18n.locale.to_s
  end

  def select_locale(locales = I18n.available_locales)
    if params[:locale]
      http_accept_language.user_preferred_languages = [ params[:locale] ]
    end

    if http_accept_language.compatible_language_from(locales).nil?
      http_accept_language.user_preferred_languages = http_accept_language.user_preferred_languages.collect do |pl|
        pls = [ pl ]

        while pl.match(/^(.*)-[^-]+$/)
          pls.push($1) if locales.include?($1) or locales.include?($1.to_sym)
          pl = $1
        end

        pls
      end.flatten
    end

    http_accept_language.compatible_language_from(locales) || I18n.default_locale
  end

  helper_method :select_locale

  def api_call_handle_error
    begin
      yield
    rescue ActiveRecord::RecordNotFound => ex
      render :text => "", :status => :not_found
    rescue LibXML::XML::Error, ArgumentError => ex
      report_error ex.message, :bad_request
    rescue ActiveRecord::RecordInvalid => ex
      message = "#{ex.record.class} #{ex.record.id}: "
      ex.record.errors.each { |attr,msg| message << "#{attr}: #{msg} (#{ex.record[attr].inspect})" }
      report_error message, :bad_request
    rescue OSM::APIError => ex
      report_error ex.message, ex.status
    rescue AbstractController::ActionNotFound => ex
      raise
    rescue Exception => ex
      logger.info("API threw unexpected #{ex.class} exception: #{ex.message}")
      ex.backtrace.each { |l| logger.info(l) }
      report_error "#{ex.class}: #{ex.message}", :internal_server_error
    end
  end

  ##
  # asserts that the request method is the +method+ given as a parameter
  # or raises a suitable error. +method+ should be a symbol, e.g: :put or :get.
  def assert_method(method)
    ok = request.send((method.to_s.downcase + "?").to_sym)
    raise OSM::APIBadMethodError.new(method) unless ok
  end

  ##
  # wrap an api call in a timeout
  def api_call_timeout
    OSM::Timer.timeout(API_TIMEOUT) do
      yield
    end
  rescue Timeout::Error
    raise OSM::APITimeoutError
  end

  ##
  # wrap a web page in a timeout
  def web_timeout
    OSM::Timer.timeout(WEB_TIMEOUT) do
      yield
    end
  rescue ActionView::Template::Error => ex
    ex = ex.original_exception

    if ex.is_a?(ActiveRecord::StatementInvalid) and ex.message =~ /execution expired/
      ex = Timeout::Error.new
    end

    if ex.is_a?(Timeout::Error)
      render :action => "timeout"
    else
      raise
    end
  rescue Timeout::Error
    render :action => "timeout"
  end

  ##
  # is the requestor logged in?
  def logged_in?
    !@user.nil?
  end

  ##
  # ensure that there is a "this_user" instance variable
  def lookup_this_user
    unless @this_user = User.active.find_by_display_name(params[:display_name])
      render_unknown_user params[:display_name]
    end
  end

  ##
  # render a "no such user" page
  def render_unknown_user(name)
    @title = t "user.no_such_user.title"
    @not_found_user = name

    respond_to do |format|
      format.html { render :template => "user/no_such_user", :status => :not_found }
      format.all { render :text => "", :status => :not_found }
    end
  end

  ##
  # Unfortunately if a PUT or POST request that has a body fails to
  # read it then Apache will sometimes fail to return the response it
  # is given to the client properly, instead erroring:
  #
  #   https://issues.apache.org/bugzilla/show_bug.cgi?id=44782
  #
  # To work round this we call rewind on the body here, which is added
  # as a filter, to force it to be fetched from Apache into a file.
  def fetch_body
    request.body.rewind
  end

  def map_layout
    request.xhr? ? 'xhr' : 'map'
  end

  def preferred_editor
    editor = if params[:editor]
      params[:editor]
    elsif @user and @user.preferred_editor
      @user.preferred_editor
    else
      DEFAULT_EDITOR
    end

    if request.env['HTTP_USER_AGENT'] =~ /MSIE|Trident/ and editor == 'id'
      editor = 'potlatch2'
    end

    editor
  end

  helper_method :preferred_editor

private 

  # extract authorisation credentials from headers, returns user = nil if none
  def get_auth_data 
    if request.env.has_key? 'X-HTTP_AUTHORIZATION'          # where mod_rewrite might have put it 
      authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
    elsif request.env.has_key? 'REDIRECT_X_HTTP_AUTHORIZATION'          # mod_fcgi 
      authdata = request.env['REDIRECT_X_HTTP_AUTHORIZATION'].to_s.split 
    elsif request.env.has_key? 'HTTP_AUTHORIZATION'         # regular location
      authdata = request.env['HTTP_AUTHORIZATION'].to_s.split
    end 
    # only basic authentication supported
    if authdata and authdata[0] == 'Basic' 
      user, pass = Base64.decode64(authdata[1]).split(':',2)
    end 
    return [user, pass] 
  end 

  # used by oauth plugin to get the current user
  def current_user
    @user
  end

  # used by oauth plugin to set the current user
  def current_user=(user)
    @user=user
  end

  # override to stop oauth plugin sending errors
  def invalid_oauth_response
  end

end
