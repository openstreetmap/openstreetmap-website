class ApplicationController < ActionController::Base
  require "timeout"

  include SessionPersistence

  protect_from_forgery :with => :exception

  add_flash_types :warning, :error

  rescue_from CanCan::AccessDenied, :with => :deny_access
  check_authorization

  before_action :fetch_body
  around_action :better_errors_allow_inline, :if => proc { Rails.env.development? }

  attr_accessor :current_user, :oauth_token

  helper_method :current_user
  helper_method :oauth_token

  private

  def authorize_web
    if session[:user]
      self.current_user = User.find_by(:id => session[:user], :status => %w[active confirmed suspended])

      if session[:fingerprint] &&
         session[:fingerprint] != current_user.fingerprint
        reset_session
        self.current_user = nil
      elsif current_user.status == "suspended"
        session.delete(:user)
        session_expires_automatically

        redirect_to :controller => "users", :action => "suspended"

      # don't allow access to any auth-requiring part of the site unless
      # the new CTs have been seen (and accept/decline chosen).
      elsif !current_user.terms_seen && flash[:skip_terms].nil?
        flash[:notice] = t "users.terms.you need to accept or decline"
        if params[:referer]
          redirect_to :controller => "users", :action => "terms", :referer => params[:referer]
        else
          redirect_to :controller => "users", :action => "terms", :referer => request.fullpath
        end
      end
    elsif session[:token]
      session[:user] = current_user.id if self.current_user = User.authenticate(:token => session[:token])
    end

    session[:fingerprint] = current_user.fingerprint if current_user && session[:fingerprint].nil?
  rescue StandardError => e
    logger.info("Exception authorizing user: #{e}")
    reset_session
    self.current_user = nil
  end

  def require_user
    unless current_user
      if request.get?
        redirect_to login_path(:referer => request.fullpath)
      else
        head :forbidden
      end
    end
  end

  def require_oauth
    @oauth_token = current_user.oauth_token(Settings.oauth_application) if current_user && Settings.key?(:oauth_application)
  end

  ##
  # require the user to have cookies enabled in their browser
  def require_cookies
    if request.cookies["_osm_session"].to_s == ""
      if params[:cookie_test].nil?
        session[:cookie_test] = true
        redirect_to params.to_unsafe_h.merge(:only_path => true, :cookie_test => "true")
        false
      else
        flash.now[:warning] = t "application.require_cookies.cookies_needed"
      end
    else
      session.delete(:cookie_test)
    end
  end

  def check_database_readable(need_api: false)
    if Settings.status == "database_offline" || (need_api && Settings.status == "api_offline")
      if request.xhr?
        report_error "Database offline for maintenance", :service_unavailable
      else
        redirect_to :controller => "site", :action => "offline"
      end
    end
  end

  def check_database_writable(need_api: false)
    if Settings.status == "database_offline" || Settings.status == "database_readonly" ||
       (need_api && (Settings.status == "api_offline" || Settings.status == "api_readonly"))
      if request.xhr?
        report_error "Database offline for maintenance", :service_unavailable
      else
        redirect_to :controller => "site", :action => "offline"
      end
    end
  end

  def check_api_readable
    if api_status == "offline"
      report_error "Database offline for maintenance", :service_unavailable
      false
    end
  end

  def check_api_writable
    unless api_status == "online"
      report_error "Database offline for maintenance", :service_unavailable
      false
    end
  end

  def database_status
    case Settings.status
    when "database_offline"
      "offline"
    when "database_readonly"
      "readonly"
    else
      "online"
    end
  end

  def api_status
    status = database_status
    if status == "online"
      case Settings.status
      when "api_offline"
        status = "offline"
      when "api_readonly"
        status = "readonly"
      end
    end
    status
  end

  def require_public_data
    unless current_user.data_public?
      report_error "You must make your edits public to upload new data", :forbidden
      false
    end
  end

  # Report and error to the user
  # (If anyone ever fixes Rails so it can set a http status "reason phrase",
  #  rather than only a status code and having the web engine make up a
  #  phrase from that, we can also put the error message into the status
  #  message. For now, rails won't let us)
  def report_error(message, status = :bad_request)
    # TODO: some sort of escaping of problem characters in the message
    response.headers["Error"] = message

    if request.headers["X-Error-Format"]&.casecmp("xml")&.zero?
      result = OSM::API.new.xml_doc
      result.root.name = "osmError"
      result.root << (XML::Node.new("status") << "#{Rack::Utils.status_code(status)} #{Rack::Utils::HTTP_STATUS_CODES[status]}")
      result.root << (XML::Node.new("message") << message)

      render :xml => result.to_s
    else
      render :plain => message, :status => status
    end
  end

  def preferred_languages
    @preferred_languages ||= if params[:locale]
                               Locale.list(params[:locale])
                             elsif current_user
                               current_user.preferred_languages
                             else
                               Locale.list(http_accept_language.user_preferred_languages)
                             end
  end

  helper_method :preferred_languages

  def set_locale
    if current_user&.languages&.empty? && !http_accept_language.user_preferred_languages.empty?
      current_user.languages = http_accept_language.user_preferred_languages
      current_user.save
    end

    I18n.locale = Locale.available.preferred(preferred_languages)

    response.headers["Vary"] = "Accept-Language"
    response.headers["Content-Language"] = I18n.locale.to_s
  end

  ##
  # wrap a web page in a timeout
  def web_timeout(&block)
    Timeout.timeout(Settings.web_timeout, Timeout::Error, &block)
  rescue ActionView::Template::Error => e
    e = e.cause

    if e.is_a?(Timeout::Error) ||
       (e.is_a?(ActiveRecord::StatementInvalid) && e.message.include?("execution expired"))
      ActiveRecord::Base.connection.raw_connection.cancel
      render :action => "timeout"
    else
      raise
    end
  rescue Timeout::Error
    ActiveRecord::Base.connection.raw_connection.cancel
    render :action => "timeout"
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
    append_content_security_policy_directives(
      :child_src => %w[http://127.0.0.1:8111 https://127.0.0.1:8112],
      :frame_src => %w[http://127.0.0.1:8111 https://127.0.0.1:8112],
      :connect_src => [Settings.nominatim_url, Settings.overpass_url, Settings.fossgis_osrm_url, Settings.graphhopper_url, Settings.fossgis_valhalla_url],
      :form_action => %w[render.openstreetmap.org],
      :style_src => %w['unsafe-inline']
    )

    case Settings.status
    when "database_offline", "api_offline"
      flash.now[:warning] = t("layouts.osm_offline")
    when "database_readonly", "api_readonly"
      flash.now[:warning] = t("layouts.osm_read_only")
    end

    request.xhr? ? "xhr" : "map"
  end

  def allow_thirdparty_images
    append_content_security_policy_directives(:img_src => %w[*])
  end

  def preferred_editor
    if params[:editor]
      params[:editor]
    elsif current_user&.preferred_editor
      current_user.preferred_editor
    else
      Settings.default_editor
    end
  end

  helper_method :preferred_editor

  def update_totp
    if Settings.key?(:totp_key)
      cookies["_osm_totp_token"] = {
        :value => ROTP::TOTP.new(Settings.totp_key, :interval => 3600).now,
        :domain => "openstreetmap.org",
        :expires => 1.hour.from_now
      }
    end
  end

  def better_errors_allow_inline
    yield
  rescue StandardError
    append_content_security_policy_directives(
      :script_src => %w['unsafe-inline'],
      :style_src => %w['unsafe-inline']
    )

    raise
  end

  def current_ability
    Ability.new(current_user)
  end

  def deny_access(_exception)
    if doorkeeper_token || current_token
      set_locale
      report_error t("oauth.permissions.missing"), :forbidden
    elsif current_user
      set_locale
      respond_to do |format|
        format.html { redirect_to :controller => "/errors", :action => "forbidden" }
        format.any { report_error t("application.permission_denied"), :forbidden }
      end
    elsif request.get?
      respond_to do |format|
        format.html { redirect_to login_path(:referer => request.fullpath) }
        format.any { head :forbidden }
      end
    else
      head :forbidden
    end
  end

  # extract authorisation credentials from headers, returns user = nil if none
  def auth_data
    if request.env.key? "X-HTTP_AUTHORIZATION" # where mod_rewrite might have put it
      authdata = request.env["X-HTTP_AUTHORIZATION"].to_s.split
    elsif request.env.key? "REDIRECT_X_HTTP_AUTHORIZATION" # mod_fcgi
      authdata = request.env["REDIRECT_X_HTTP_AUTHORIZATION"].to_s.split
    elsif request.env.key? "HTTP_AUTHORIZATION" # regular location
      authdata = request.env["HTTP_AUTHORIZATION"].to_s.split
    end
    # only basic authentication supported
    user, pass = Base64.decode64(authdata[1]).split(":", 2) if authdata && authdata[0] == "Basic"
    [user, pass]
  end

  # override to stop oauth plugin sending errors
  def invalid_oauth_response; end

  # clean any referer parameter
  def safe_referer(referer)
    begin
      referer = URI.parse(referer)

      if referer.scheme == "http" || referer.scheme == "https"
        referer.scheme = nil
        referer.host = nil
        referer.port = nil
      elsif referer.scheme || referer.host || referer.port
        referer = nil
      end

      referer = nil if referer&.path&.first != "/"
    rescue URI::InvalidURIError
      referer = nil
    end

    referer&.to_s
  end

  def scope_enabled?(scope)
    doorkeeper_token&.includes_scope?(scope) || current_token&.includes_scope?(scope)
  end

  helper_method :scope_enabled?
end
