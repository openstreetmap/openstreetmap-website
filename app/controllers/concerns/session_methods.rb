module SessionMethods
  extend ActiveSupport::Concern

  private

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

    target = referer || session[:referer] || url_for(:controller => :site, :action => :index)

    # The user is logged in, so decide where to send them:
    #
    # - If they haven't seen the contributor terms, send them there.
    # - If they have a block on them, show them that.
    # - If they were referred to the login, send them back there.
    # - Otherwise, send them to the home page.
    if !user.terms_seen
      redirect_to :controller => :users, :action => :terms, :referer => target
    elsif user.blocked_on_view
      redirect_to user.blocked_on_view, :referer => target
    else
      redirect_to target
    end

    session.delete(:remember_me)
    session.delete(:referer)
  end

  ##
  # process a failed login
  def failed_login(message, username = nil)
    flash[:error] = message

    redirect_to :controller => "sessions", :action => "new", :referer => session[:referer],
                :username => username, :remember_me => session[:remember_me]

    session.delete(:remember_me)
    session.delete(:referer)
  end

  ##
  #
  def unconfirmed_login(user)
    session[:token] = user.tokens.create.token

    redirect_to :controller => "confirmations", :action => "confirm", :display_name => user.display_name

    session.delete(:remember_me)
    session.delete(:referer)
  end

  ##
  #
  def disable_terms_redirect
    # this is necessary otherwise going to the user terms page, when
    # having not agreed already would cause an infinite redirect loop.
    # it's .now so that this doesn't propagate to other pages.
    flash.now[:skip_terms] = true
  end
end
