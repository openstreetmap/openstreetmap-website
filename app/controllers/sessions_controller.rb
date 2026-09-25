# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include SessionMethods

  layout :site_layout

  before_action :authorize_web, :except => [:destroy]
  before_action -> { authorize_web(:skip_terms => true) }, :only => [:destroy]
  before_action :set_locale
  before_action :check_database_readable
  before_action :require_cookies, :only => [:new]

  authorize_resource :class => false

  allow_all_form_action :only => :new

  def new
    referer = safe_referer(params[:referer]) if params[:referer]

    @safe_referer = referer
    @safe_referer = nil if referer != params[:referer]

    parse_oauth_referer referer
  end

  def create
    session[:remember_me] = params[:remember_me] == "yes"
    pp "create/BEFORE"
    super do |user|
      @safe_referer = safe_referer(params[:referer]) if params[:referer]
      pp ["create/BLOCK", user, @safe_referer]
      # successful_login(user, referer)
      session[:user] = user.id
      session[:fingerprint] = user.fingerprint
      session_expires_after 28.days if session[:remember_me]

      cookies.delete :_osm_anonymous_notes_count
    end
    pp "create/AFTER"
  rescue Exception
    pp "create/RESCUE"
    pp $!
    raise
  ensure
    pp "create/ENSURE"
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
    user = User.lookup(username)

    if user&.password_expired?
      redirect_to user_forgot_password_path, :warning => t("sessions.new.reset_to_login")
    elsif user&.password_matches?(password)
      if user.pending?
        unconfirmed_login(user, referer)
      elsif user.suspended?
        failed_login({ :partial => "sessions/suspended_flash" }, username, referer)
      else
        successful_login(user, referer)
      end
    else
      failed_login(t("sessions.new.auth failure"), username, referer)
    end
  end

  def after_sign_in_path_for(user)
    target = @safe_referer || url_for(:controller => :site, :action => :index)

    # The user is logged in, so decide where to send them:
    #
    # - If they haven't seen the contributor terms, send them there.
    # - If they have a block on them, show them that.
    # - If they were referred to the login, send them back there.
    # - Otherwise, send them to the home page.
    if !user.terms_seen
      account_terms_path(:referer => target)
    elsif user.blocked_on_view
      # TODO: :referer => target
      # redirect_to user.blocked_on_view, :referer => target
      user.blocked_on_view
    else
      target
    end
  end
end
