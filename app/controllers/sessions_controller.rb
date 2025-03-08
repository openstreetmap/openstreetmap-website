class SessionsController < ApplicationController
  include SessionMethods

  layout "site"

  before_action :authorize_web, :except => [:destroy]
  before_action -> { authorize_web(:skip_terms => true) }, :only => [:destroy]
  before_action :set_locale
  before_action :check_database_readable
  before_action :require_cookies, :only => [:new]

  authorize_resource :class => false

  allow_all_form_action :only => :new

  def new
    referer = safe_referer(params[:referer]) if params[:referer]

    parse_oauth_referer referer
  end

  def create
    session[:remember_me] = params[:remember_me] == "yes"

    referer = safe_referer(params[:referer]) if params[:referer]

    password_authentication(params[:username].strip, params[:password], referer)
  end

  def destroy
    @title = t ".title"

    if request.post?
      session.delete(:pending_user)
      session.delete(:user)
      session_expires_automatically

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || { :controller => "site", :action => "index" }
    end
  end

  private

  ##
  # handle password authentication
  def password_authentication(username, password, referer = nil)
    if (user = User.authenticate(:username => username, :password => password))
      successful_login(user, referer)
    elsif (user = User.authenticate(:username => username, :password => password, :pending => true))
      unconfirmed_login(user, referer)
    elsif User.authenticate(:username => username, :password => password, :suspended => true)
      failed_login({ :partial => "sessions/suspended_flash" }, username, referer)
    else
      failed_login(t("sessions.new.auth failure"), username, referer)
    end
  end
end
