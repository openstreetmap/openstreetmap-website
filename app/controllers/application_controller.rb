class ApplicationController < ActionController::Base
  require "timeout"

  include SessionPersistence

  protect_from_forgery :with => :exception

  add_flash_types :warning, :error

  rescue_from CanCan::AccessDenied, :with => :deny_access
  check_authorization

  rescue_from RailsParam::InvalidParameterError, :with => :invalid_parameter

  before_action :fetch_body

  attr_accessor :current_user, :oauth_token

  helper_method :current_user
  helper_method :oauth_token

  def self.allow_thirdparty_images(**options)
    content_security_policy(**options) do |policy|
      policy.img_src("*", :data)
    end
  end

  def self.allow_social_login(**options)
    content_security_policy(options) do |policy|
      policy.form_action(*policy.form_action, "accounts.google.com", "*.facebook.com", "login.microsoftonline.com", "github.com", "meta.wikimedia.org")
    end
  end

  def self.allow_all_form_action(**options)
    content_security_policy(options) do |policy|
      policy.form_action(nil)
    end
  end

  private

  def authorize_web(skip_terms: false)
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
      elsif !current_user.terms_seen && !skip_terms
        flash[:notice] = t "accounts.terms.show.you need to accept or decline"
        if params[:referer]
          redirect_to account_terms_path(:referer => params[:referer])
        else
          redirect_to account_terms_path(:referer => request.fullpath)
        end
      end
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
       (need_api && %w[api_offline api_readonly].include?(Settings.status))
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

    if request.headers["X-Error-Format"]&.casecmp?("xml")
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
  def web_timeout(&)
    raise Timeout::Error if Settings.web_timeout.negative?

    Timeout.timeout(Settings.web_timeout, &)
  rescue ActionView::Template::Error => e
    e = e.cause

    if e.is_a?(Timeout::Error) ||
       (e.is_a?(ActiveRecord::StatementInvalid) && e.message.include?("execution expired"))
      respond_to_timeout
    else
      raise
    end
  rescue Timeout::Error
    respond_to_timeout
  end

  def respond_to_timeout
    ActiveRecord::Base.connection.raw_connection.cancel
    render :action => "timeout", :status => :gateway_timeout
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
    policy = request.content_security_policy.clone

    policy.connect_src(*policy.connect_src, "http://127.0.0.1:8111", Settings.nominatim_url, Settings.overpass_url, Settings.fossgis_osrm_url, Settings.graphhopper_url, Settings.fossgis_valhalla_url)
    policy.form_action(*policy.form_action, "render.openstreetmap.org")
    policy.style_src(*policy.style_src, :unsafe_inline)

    request.content_security_policy = policy

    flash.now[:warning] = { :partial => "layouts/offline_flash" } unless api_status == "online"

    request.xhr? ? "xhr" : "map"
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

  def preferred_color_scheme(subject)
    if current_user
      current_user.preferences.find_by(:k => "#{subject}.color_scheme")&.v || "auto"
    else
      "auto"
    end
  end

  helper_method :preferred_editor, :preferred_color_scheme

  def update_totp
    if Settings.key?(:totp_key)
      cookies["_osm_totp_token"] = {
        :value => ROTP::TOTP.new(Settings.totp_key, :interval => 3600).now,
        :domain => "openstreetmap.org",
        :expires => 1.hour.from_now
      }
    end
  end

  def current_ability
    Ability.new(current_user)
  end

  def deny_access(_exception)
    if current_user
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

  def invalid_parameter(_exception)
    if request.get?
      respond_to do |format|
        format.html { redirect_to :controller => "/errors", :action => "bad_request" }
        format.any { head :bad_request }
      end
    else
      head :bad_request
    end
  end

  # clean any referer parameter
  def safe_referer(referer)
    begin
      referer = URI.parse(referer)

      if %w[http https].include?(referer.scheme)
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
end
