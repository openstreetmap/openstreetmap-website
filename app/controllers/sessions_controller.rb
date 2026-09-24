# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include SessionMethods

  layout :site_layout

  skip_before_action :verify_signed_out_user
  skip_before_action :require_no_authentication

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
    sign_out(:user)
    super do |user|
      @safe_referer = safe_referer(params[:referer]) if params[:referer]
      # TODO: this is reproducing `successful_login(user, @safe_referer)`
      session[:fingerprint] = user.fingerprint
      session_expires_after 28.days if session[:remember_me]

      cookies.delete :_osm_anonymous_notes_count
      session.delete(:remember_me)
    end
  end

  def destroy
    return unless request.delete? || request.post?

    @title = t ".title"

    super do
      session.delete(:pending_user)

      # TODO: do we need this?
      session_expires_automatically

      safe_referer(params[:referer]) if params[:referer]
    end
  end

  private

  # TODO: this is taken from `successful_login`. DRY it up.
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

  def after_sign_out_path_for(_user)
    referer = safe_referer(params[:referer]) if params[:referer]
    referer || { :controller => "site", :action => "index" }
  end
end
