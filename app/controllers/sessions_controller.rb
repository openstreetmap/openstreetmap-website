# frozen_string_literal: true

class SessionsController < ApplicationController
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

    referer = safe_referer(params[:referer]) if params[:referer]

    password_authentication(params.expect(:username).strip, params.expect(:password), referer)
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
end
