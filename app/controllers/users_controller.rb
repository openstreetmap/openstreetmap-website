class UsersController < ApplicationController
  include EmailMethods
  include SessionMethods
  include UserMethods
  include PaginationMethods

  layout "site"

  skip_before_action :verify_authenticity_token, :only => [:auth_success]
  before_action :disable_terms_redirect, :only => [:terms, :save]
  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable, :only => [:new, :go_public]
  before_action :require_cookies, :only => [:new]
  before_action :lookup_user_by_name, :only => [:set_status, :destroy]

  allow_thirdparty_images :only => :show
  allow_social_login :only => :new

  ##
  # display a list of users matching specified criteria
  def index
    if request.post?
      ids = params[:user].keys.collect(&:to_i)

      User.where(:id => ids).update_all(:status => "confirmed") if params[:confirm]
      User.where(:id => ids).update_all(:status => "deleted") if params[:hide]

      redirect_to url_for(:status => params[:status], :ip => params[:ip], :page => params[:page])
    else
      @params = params.permit(:status, :ip, :before, :after)

      users = User.all
      users = users.where(:status => @params[:status]) if @params[:status]
      users = users.where(:creation_address => @params[:ip]) if @params[:ip]

      @users_count = users.limit(501).count
      @users_count = I18n.t("count.at_least_pattern", :count => 500) if @users_count > 500

      @users, @newer_users_id, @older_users_id = get_page_items(users, :limit => 50)

      render :partial => "page" if turbo_frame_request_id == "pagination"
    end
  end

  def show
    @user = User.find_by(:display_name => params[:display_name])

    if @user &&
       (@user.visible? || current_user&.administrator?)
      @title = @user.display_name
    else
      render_unknown_user params[:display_name]
    end
  end

  def new
    @title = t ".title"
    @referer = safe_referer(params[:referer])

    parse_oauth_referer @referer

    if current_user
      # The user is logged in already, so don't show them the signup
      # page, instead send them to the home page
      redirect_to @referer || { :controller => "site", :action => "index" }
    elsif params.key?(:auth_provider) && params.key?(:auth_uid)
      @email_hmac = params[:email_hmac]

      self.current_user = User.new(:email => params[:email],
                                   :display_name => params[:nickname],
                                   :auth_provider => params[:auth_provider],
                                   :auth_uid => params[:auth_uid])

      if current_user.valid? || current_user.errors[:email].empty?
        flash.now[:notice] = render_to_string :partial => "auth_association"
      else
        flash.now[:warning] = t ".duplicate_social_email"
      end
    else
      check_signup_allowed

      self.current_user = User.new
    end
  end

  def create
    self.current_user = User.new(user_params)

    if check_signup_allowed(current_user.email)
      if current_user.auth_uid.present?
        # We are creating an account with external authentication and
        # no password was specified so create a random one
        current_user.pass_crypt = SecureRandom.base64(16)
        current_user.pass_crypt_confirmation = current_user.pass_crypt
      end

      if current_user.invalid?
        # Something is wrong with a new user, so rerender the form
        render :action => "new"
      else
        # Save the user record
        save_new_user params[:email_hmac], params[:referer]
      end
    end
  end

  ##
  # destroy a user, marking them as deleted and removing personal data
  def destroy
    @user.soft_destroy!
    redirect_to user_path(:display_name => params[:display_name])
  end

  def terms
    @legale = params[:legale] || OSM.ip_to_country(request.remote_ip) || Settings.default_legale
    @text = OSM.legal_text_for_country(@legale)

    if request.xhr?
      render :partial => "terms"
    else
      @title = t ".title"

      if current_user&.terms_agreed?
        # Already agreed to terms, so just show settings
        redirect_to edit_account_path
      elsif current_user.nil?
        redirect_to login_path(:referer => request.fullpath)
      end
    end
  end

  def save
    @title = t "users.new.title"

    if params[:decline] || !(params[:read_tou] && params[:read_ct])
      if current_user
        current_user.terms_seen = true

        flash[:notice] = { :partial => "users/terms_declined_flash" } if current_user.save

        referer = safe_referer(params[:referer]) if params[:referer]

        redirect_to referer || edit_account_path
      elsif params[:decline]
        redirect_to t("users.terms.declined"), :allow_other_host => true
      else
        redirect_to :action => :terms
      end
    elsif current_user
      unless current_user.terms_agreed?
        current_user.consider_pd = params[:user][:consider_pd]
        current_user.tou_agreed = Time.now.utc
        current_user.terms_agreed = Time.now.utc
        current_user.terms_seen = true

        flash[:notice] = t "users.new.terms accepted" if current_user.save
      end

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || edit_account_path
    end
  end

  def go_public
    current_user.data_public = true
    current_user.save
    flash[:notice] = t ".flash success"
    redirect_to edit_account_path
  end

  ##
  # sets a user's status
  def set_status
    @user.activate! if params[:event] == "activate"
    @user.confirm! if params[:event] == "confirm"
    @user.unconfirm! if params[:event] == "unconfirm"
    @user.hide! if params[:event] == "hide"
    @user.unhide! if params[:event] == "unhide"
    @user.unsuspend! if params[:event] == "unsuspend"
    redirect_to user_path(:display_name => params[:display_name])
  end

  ##
  # omniauth success callback
  def auth_success
    referer = request.env["omniauth.params"]["referer"]
    auth_info = request.env["omniauth.auth"]

    provider = auth_info[:provider]
    uid = auth_info[:uid]
    name = auth_info[:info][:name]
    email = auth_info[:info][:email]

    email_verified = case provider
                     when "openid"
                       uid.match(%r{https://www.google.com/accounts/o8/id?(.*)}) ||
                       uid.match(%r{https://me.yahoo.com/(.*)})
                     when "google", "facebook", "microsoft", "github", "wikipedia"
                       true
                     else
                       false
                     end

    if settings = session.delete(:new_user_settings)
      current_user.auth_provider = provider
      current_user.auth_uid = uid

      update_user(current_user, settings)

      flash.discard

      session[:user_errors] = current_user.errors.as_json

      redirect_to edit_account_path
    else
      user = User.find_by(:auth_provider => provider, :auth_uid => uid)

      if user.nil? && provider == "google"
        openid_url = auth_info[:extra][:id_info]["openid_id"]
        user = User.find_by(:auth_provider => "openid", :auth_uid => openid_url) if openid_url
        user&.update(:auth_provider => provider, :auth_uid => uid)
      end

      if user
        case user.status
        when "pending"
          unconfirmed_login(user, referer)
        when "active", "confirmed"
          successful_login(user, referer)
        when "suspended"
          failed_login({ :partial => "sessions/suspended_flash" }, user.display_name, referer)
        else
          failed_login(t("sessions.new.auth failure"), user.display_name, referer)
        end
      else
        email_hmac = UsersController.message_hmac(email) if email_verified && email
        redirect_to :action => "new", :nickname => name, :email => email, :email_hmac => email_hmac,
                    :auth_provider => provider, :auth_uid => uid, :referer => referer
      end
    end
  end

  ##
  # omniauth failure callback
  def auth_failure
    flash[:error] = t(params[:message], :scope => "users.auth_failure", :default => t(".unknown_error"))

    origin = safe_referer(params[:origin]) if params[:origin]

    redirect_to origin || login_url
  end

  def self.message_hmac(text)
    sha256 = Digest::SHA256.new
    sha256 << Rails.application.key_generator.generate_key("openstreetmap/email_address")
    sha256 << text
    Base64.urlsafe_encode64(sha256.digest)
  end

  private

  def save_new_user(email_hmac, referer = nil)
    current_user.data_public = true
    current_user.description = "" if current_user.description.nil?
    current_user.creation_address = request.remote_ip
    current_user.languages = http_accept_language.user_preferred_languages
    current_user.terms_agreed = Time.now.utc
    current_user.tou_agreed = Time.now.utc
    current_user.terms_seen = true

    if current_user.auth_uid.blank?
      current_user.auth_provider = nil
      current_user.auth_uid = nil
    elsif email_hmac && ActiveSupport::SecurityUtils.secure_compare(email_hmac, UsersController.message_hmac(current_user.email))
      current_user.activate
    end

    if current_user.save
      SIGNUP_IP_LIMITER&.update(request.remote_ip)
      SIGNUP_EMAIL_LIMITER&.update(canonical_email(current_user.email))

      flash[:matomo_goal] = Settings.matomo["goals"]["signup"] if defined?(Settings.matomo)

      referer = welcome_path(welcome_options(referer))

      if current_user.status == "active"
        successful_login(current_user, referer)
      else
        session[:pending_user] = current_user.id
        UserMailer.signup_confirm(current_user, current_user.generate_token_for(:new_user), referer).deliver_later
        redirect_to :controller => :confirmations, :action => :confirm, :display_name => current_user.display_name
      end
    else
      render :action => "new", :referer => params[:referer]
    end
  end

  def welcome_options(referer = nil)
    uri = URI(referer) if referer.present?

    return { "oauth_return_url" => uri&.to_s } if uri&.path == oauth_authorization_path

    begin
      %r{map=(.*)/(.*)/(.*)}.match(uri.fragment) do |m|
        editor = Rack::Utils.parse_query(uri.query).slice("editor")
        return { "zoom" => m[1], "lat" => m[2], "lon" => m[3] }.merge(editor)
      end
    rescue StandardError
      # Use default
    end
  end

  ##
  # ensure that there is a "user" instance variable
  def lookup_user_by_name
    @user = User.find_by(:display_name => params[:display_name])
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => "view", :display_name => params[:display_name] unless @user
  end

  ##
  # return permitted user parameters
  def user_params
    params.require(:user).permit(:email, :display_name,
                                 :auth_provider, :auth_uid,
                                 :pass_crypt, :pass_crypt_confirmation,
                                 :consider_pd)
  end

  ##
  # check signup acls
  def check_signup_allowed(email = nil)
    domain = if email.nil?
               nil
             else
               email.split("@").last
             end

    mx_servers = if domain.nil?
                   nil
                 else
                   domain_mx_servers(domain)
                 end

    return true if Acl.allow_account_creation(request.remote_ip, :domain => domain, :mx => mx_servers)

    blocked = Acl.no_account_creation(request.remote_ip, :domain => domain, :mx => mx_servers)

    blocked ||= SIGNUP_IP_LIMITER && !SIGNUP_IP_LIMITER.allow?(request.remote_ip)

    blocked ||= email && SIGNUP_EMAIL_LIMITER && !SIGNUP_EMAIL_LIMITER.allow?(canonical_email(email))

    if blocked
      logger.info "Blocked signup from #{request.remote_ip} for #{email}"

      render :action => "blocked"
    end

    !blocked
  end
end
