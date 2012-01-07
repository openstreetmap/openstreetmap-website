class ApplicationController < ActionController::Base

  protect_from_forgery

  if STATUS == :database_readonly or STATUS == :database_offline
    after_filter :clear_session
    wrap_parameters false

    def clear_session
      session.clear
    end

    def self.cache_sweeper(*sweepers)
    end
  end

  def authorize_web
    if session[:user]
      @user = User.where(:id => session[:user]).where("status IN ('active', 'confirmed', 'suspended')").first

      if @user.display_name != cookies["_osm_username"]
        logger.info "Session user '#{@user.display_name}' does not match cookie user '#{cookies['_osm_username']}'"
        reset_session
        @user = nil
      elsif @user.status == "suspended"
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
    redirect_to :controller => 'user', :action => 'login', :referer => request.fullpath unless @user
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
      if not  @user.active_blocks.empty?
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
    if STATUS == :database_offline or STATUS == :api_offline
      report_error "Database offline for maintenance", :service_unavailable
      return false
    end
  end

  def check_api_writable
    if STATUS == :database_offline or STATUS == :database_readonly or
       STATUS == :api_offline or STATUS == :api_readonly
      report_error "Database offline for maintenance", :service_unavailable
      return false
    end
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
      render :text => message, :status => status
    end
  end
  
  def set_locale
    response.header['Vary'] = 'Accept-Language'

    if @user
      if !@user.languages.empty?
        request.user_preferred_languages = @user.languages
        response.header['Vary'] = '*'
      elsif !request.user_preferred_languages.empty?
        @user.languages = request.user_preferred_languages
        @user.save
      end
    end

    if request.compatible_language_from(I18n.available_locales).nil?
      request.user_preferred_languages = request.user_preferred_languages.collect do |pl|
        pls = [ pl ]

        while pl.match(/^(.*)-[^-]+$/)
          pls.push($1) if I18n.available_locales.include?($1.to_sym)
          pl = $1
        end

        pls
      end.flatten

      if @user and not request.compatible_language_from(I18n.available_locales).nil?
        @user.languages = request.user_preferred_languages
        @user.save        
      end
    end

    I18n.locale = request.compatible_language_from(I18n.available_locales) || I18n.default_locale

    response.headers['Content-Language'] = I18n.locale.to_s
  end

  def api_call_handle_error
    begin
      yield
    rescue ActiveRecord::RecordNotFound => ex
      render :nothing => true, :status => :not_found
    rescue LibXML::XML::Error, ArgumentError => ex
      report_error ex.message, :bad_request
    rescue ActiveRecord::RecordInvalid => ex
      message = "#{ex.record.class} #{ex.record.id}: "
      ex.record.errors.each { |attr,msg| message << "#{attr}: #{msg} (#{ex.record[attr].inspect})" }
      report_error message, :bad_request
    rescue OSM::APIError => ex
      report_error ex.message, ex.status
    rescue ActionController::UnknownAction => ex
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

    if ex.is_a?(ActiveRecord::StatementInvalid) and ex.message =~ /^Timeout::Error/
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
  # extend caches_action to include the parameters, locale and logged in
  # status in all cache keys
  def self.caches_action(*actions)
    options = actions.extract_options!
    cache_path = options[:cache_path] || Hash.new

    options[:unless] = case options[:unless]
                       when NilClass then Array.new
                       when Array then options[:unless]
                       else unlessp = [ options[:unless] ]
                       end

    options[:unless].push(Proc.new do |controller|
      controller.params.include?(:page)
    end)

    options[:cache_path] = Proc.new do |controller|
      cache_path.merge(controller.params).merge(:locale => I18n.locale)
    end

    actions.push(options)

    super *actions
  end

  ##
  # extend expire_action to expire all variants
  def expire_action(options = {})
    I18n.available_locales.each do |locale|
      super options.merge(:locale => locale)
    end
  end

  ##
  # is the requestor logged in?
  def logged_in?
    !@user.nil?
  end

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
