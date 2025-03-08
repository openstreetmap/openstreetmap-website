module SessionMethods
  extend ActiveSupport::Concern

  private

  ##
  # Read @preferred_auth_provider and @client_app_name from oauth2 authorization request's referer
  def parse_oauth_referer(referer)
    referer_query = URI(referer).query if referer
    return unless referer_query

    ref_params = CGI.parse referer_query
    preferred = ref_params["preferred_auth_provider"].first
    @preferred_auth_provider = preferred if preferred && Settings.key?(:"#{preferred}_auth_id")
    @client_app_name = Oauth2Application.where(:uid => ref_params["client_id"].first).pick(:name)
  end

  ##
  # return the URL to use for authentication
  def auth_url(provider, uid, referer = nil)
    params = { :provider => provider }

    params[:openid_url] = uid if provider == "openid"

    if referer.nil?
      params[:origin] = request.path
    else
      params[:origin] = "#{request.path}?referer=#{CGI.escape(referer)}"
      params[:referer] = referer
    end

    auth_path(params)
  end

  ##
  # process a successful login
  def successful_login(user, referer = nil)
    session[:user] = user.id
    session[:fingerprint] = user.fingerprint
    session_expires_after 28.days if session[:remember_me]

    cookies.delete :_osm_anonymous_notes_count

    target = referer || url_for(:controller => :site, :action => :index)

    # The user is logged in, so decide where to send them:
    #
    # - If they haven't seen the contributor terms, send them there.
    # - If they have a block on them, show them that.
    # - If they were referred to the login, send them back there.
    # - Otherwise, send them to the home page.
    if !user.terms_seen
      redirect_to account_terms_path(:referer => target)
    elsif user.blocked_on_view
      redirect_to user.blocked_on_view, :referer => target
    else
      redirect_to target
    end

    session.delete(:remember_me)
  end

  ##
  # process a failed login
  def failed_login(message, username, referer = nil)
    flash[:error] = message

    redirect_to :controller => "sessions", :action => "new", :referer => referer,
                :username => username, :remember_me => session[:remember_me]

    session.delete(:remember_me)
  end

  ##
  #
  def unconfirmed_login(user, referer = nil)
    session[:pending_user] = user.id

    redirect_to :controller => "confirmations", :action => "confirm",
                :display_name => user.display_name, :referer => referer

    session.delete(:remember_me)
  end
end
