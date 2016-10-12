class UserController < ApplicationController
  layout "site", :except => [:api_details]

  skip_before_action :verify_authenticity_token, :only => [:api_read, :api_details, :api_gpx_files, :auth_success]
  before_action :disable_terms_redirect, :only => [:terms, :save, :logout, :api_details]
  before_action :authorize, :only => [:api_details, :api_gpx_files]
  before_action :authorize_web, :except => [:api_read, :api_details, :api_gpx_files]
  before_action :set_locale, :except => [:api_read, :api_details, :api_gpx_files]
  before_action :require_user, :only => [:account, :go_public, :make_friend, :remove_friend]
  before_action :require_self, :only => [:account]
  before_action :check_database_readable, :except => [:login, :api_read, :api_details, :api_gpx_files]
  before_action :check_database_writable, :only => [:new, :account, :confirm, :confirm_email, :lost_password, :reset_password, :go_public, :make_friend, :remove_friend]
  before_action :check_api_readable, :only => [:api_read, :api_details, :api_gpx_files]
  before_action :require_allow_read_prefs, :only => [:api_details]
  before_action :require_allow_read_gpx, :only => [:api_gpx_files]
  before_action :require_cookies, :only => [:new, :login, :confirm]
  before_action :require_administrator, :only => [:set_status, :delete, :list]
  around_action :api_call_handle_error, :only => [:api_read, :api_details, :api_gpx_files]
  before_action :lookup_user_by_id, :only => [:api_read]
  before_action :lookup_user_by_name, :only => [:set_status, :delete]

  def terms
    @legale = params[:legale] || OSM.ip_to_country(request.remote_ip) || DEFAULT_LEGALE
    @text = OSM.legal_text_for_country(@legale)

    if request.xhr?
      render :partial => "terms"
    else
      @title = t "user.terms.title"

      if @user && @user.terms_agreed?
        # Already agreed to terms, so just show settings
        redirect_to :action => :account, :display_name => @user.display_name
      elsif @user.nil? && session[:new_user].nil?
        redirect_to :action => :login, :referer => request.fullpath
      end
    end
  end

  def save
    @title = t "user.new.title"

    if params[:decline]
      if @user
        @user.terms_seen = true

        if @user.save
          flash[:notice] = t("user.new.terms declined", :url => t("user.new.terms declined url")).html_safe
        end

        if params[:referer]
          redirect_to params[:referer]
        else
          redirect_to :action => :account, :display_name => @user.display_name
        end
      else
        redirect_to t("user.terms.declined")
      end
    elsif @user
      unless @user.terms_agreed?
        @user.consider_pd = params[:user][:consider_pd]
        @user.terms_agreed = Time.now.getutc
        @user.terms_seen = true

        flash[:notice] = t "user.new.terms accepted" if @user.save
      end

      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :action => :account, :display_name => @user.display_name
      end
    else
      @user = session.delete(:new_user)

      if check_signup_allowed(@user.email)
        @user.data_public = true
        @user.description = "" if @user.description.nil?
        @user.creation_ip = request.remote_ip
        @user.languages = http_accept_language.user_preferred_languages
        @user.terms_agreed = Time.now.getutc
        @user.terms_seen = true

        if @user.auth_uid.nil? || @user.auth_uid.empty?
          @user.auth_provider = nil
          @user.auth_uid = nil
        end

        if @user.save
          flash[:piwik_goal] = PIWIK["goals"]["signup"] if defined?(PIWIK)

          referer = welcome_path

          begin
            uri = URI(session[:referer])
            %r{map=(.*)/(.*)/(.*)}.match(uri.fragment) do |m|
              editor = Rack::Utils.parse_query(uri.query).slice("editor")
              referer = welcome_path({ "zoom" => m[1],
                                       "lat" => m[2],
                                       "lon" => m[3] }.merge(editor))
            end
          rescue
            # Use default
          end

          if @user.status == "active"
            session[:referer] = referer
            successful_login(@user)
          else
            session[:token] = @user.tokens.create.token
            Notifier.signup_confirm(@user, @user.tokens.create(:referer => referer)).deliver_now
            redirect_to :action => "confirm", :display_name => @user.display_name
          end
        else
          render :action => "new", :referer => params[:referer]
        end
      end
    end
  end

  def account
    @title = t "user.account.title"
    @tokens = @user.oauth_tokens.authorized

    if params[:user] && params[:user][:display_name] && params[:user][:description]
      if params[:user][:auth_provider].blank? ||
         (params[:user][:auth_provider] == @user.auth_provider &&
          params[:user][:auth_uid] == @user.auth_uid)
        update_user(@user, params)
      else
        session[:new_user_settings] = params
        redirect_to auth_url(params[:user][:auth_provider], params[:user][:auth_uid])
      end
    elsif errors = session.delete(:user_errors)
      errors.each do |attribute, error|
        @user.errors.add(attribute, error)
      end
    end
  end

  def go_public
    @user.data_public = true
    @user.save
    flash[:notice] = t "user.go_public.flash success"
    redirect_to :action => "account", :display_name => @user.display_name
  end

  def lost_password
    @title = t "user.lost_password.title"

    if params[:user] && params[:user][:email]
      user = User.visible.find_by_email(params[:user][:email])

      if user.nil?
        users = User.visible.where("LOWER(email) = LOWER(?)", params[:user][:email])

        user = users.first if users.count == 1
      end

      if user
        token = user.tokens.create
        Notifier.lost_password(user, token).deliver_now
        flash[:notice] = t "user.lost_password.notice email on way"
        redirect_to :action => "login"
      else
        flash.now[:error] = t "user.lost_password.notice email cannot find"
      end
    end
  end

  def reset_password
    @title = t "user.reset_password.title"

    if params[:token]
      token = UserToken.find_by_token(params[:token])

      if token
        @user = token.user

        if params[:user]
          @user.pass_crypt = params[:user][:pass_crypt]
          @user.pass_crypt_confirmation = params[:user][:pass_crypt_confirmation]
          @user.status = "active" if @user.status == "pending"
          @user.email_valid = true

          if @user.save
            token.destroy
            flash[:notice] = t "user.reset_password.flash changed"
            successful_login(@user)
          end
        end
      else
        flash[:error] = t "user.reset_password.flash token bad"
        redirect_to :action => "lost_password"
      end
    else
      render :text => "", :status => :bad_request
    end
  end

  def new
    @title = t "user.new.title"
    @referer = params[:referer] || session[:referer]

    if @user
      # The user is logged in already, so don't show them the signup
      # page, instead send them to the home page
      if @referer
        redirect_to @referer
      else
        redirect_to :controller => "site", :action => "index"
      end
    elsif params.key?(:auth_provider) && params.key?(:auth_uid)
      @user = User.new(:email => params[:email],
                       :email_confirmation => params[:email],
                       :display_name => params[:nickname],
                       :auth_provider => params[:auth_provider],
                       :auth_uid => params[:auth_uid])

      flash.now[:notice] = render_to_string :partial => "auth_association"
    else
      check_signup_allowed
    end
  end

  def create
    @user = User.new(user_params)

    if check_signup_allowed(@user.email)
      session[:referer] = params[:referer]

      @user.status = "pending"

      if @user.auth_provider.present? && @user.pass_crypt.empty?
        # We are creating an account with external authentication and
        # no password was specified so create a random one
        @user.pass_crypt = SecureRandom.base64(16)
        @user.pass_crypt_confirmation = @user.pass_crypt
      end

      if @user.invalid?
        # Something is wrong with a new user, so rerender the form
        render :action => "new"
      elsif @user.auth_provider.present?
        # Verify external authenticator before moving on
        session[:new_user] = @user
        redirect_to auth_url(@user.auth_provider, @user.auth_uid)
      else
        # Save the user record
        session[:new_user] = @user
        redirect_to :action => :terms
      end
    end
  end

  def login
    session[:referer] = params[:referer] if params[:referer]

    if params[:username].present? && params[:password].present?
      session[:remember_me] ||= params[:remember_me]
      password_authentication(params[:username], params[:password])
    elsif params[:openid_url].present?
      session[:remember_me] ||= params[:remember_me_openid]
      redirect_to auth_url("openid", params[:openid_url], params[:referer])
    end
  end

  def logout
    @title = t "user.logout.title"

    if params[:session] == request.session_options[:id]
      if session[:token]
        token = UserToken.find_by_token(session[:token])
        token.destroy if token
        session.delete(:token)
      end
      session.delete(:user)
      session_expires_automatically
      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :controller => "site", :action => "index"
      end
    end
  end

  def confirm
    if request.post?
      token = UserToken.find_by_token(params[:confirm_string])
      if token && token.user.active?
        flash[:error] = t("user.confirm.already active")
        redirect_to :action => "login"
      elsif !token || token.expired?
        flash[:error] = t("user.confirm.unknown token")
        redirect_to :action => "confirm"
      else
        user = token.user
        user.status = "active"
        user.email_valid = true
        flash[:notice] = gravatar_status_message(user) if gravatar_enable(user)
        user.save!
        referer = token.referer
        token.destroy

        if session[:token]
          token = UserToken.find_by_token(session[:token])
          session.delete(:token)
        else
          token = nil
        end

        if token.nil? || token.user != user
          flash[:notice] = t("user.confirm.success")
          redirect_to :action => :login, :referer => referer
        else
          token.destroy

          session[:user] = user.id

          redirect_to referer || welcome_path
        end
      end
    else
      user = User.find_by_display_name(params[:display_name])

      redirect_to root_path if user.nil? || user.active?
    end
  end

  def confirm_resend
    user = User.find_by_display_name(params[:display_name])
    token = UserToken.find_by_token(session[:token])

    if user.nil? || token.nil? || token.user != user
      flash[:error] = t "user.confirm_resend.failure", :name => params[:display_name]
    else
      Notifier.signup_confirm(user, user.tokens.create).deliver_now
      flash[:notice] = t("user.confirm_resend.success", :email => user.email, :sender => SUPPORT_EMAIL).html_safe
    end

    redirect_to :action => "login"
  end

  def confirm_email
    if request.post?
      token = UserToken.find_by_token(params[:confirm_string])
      if token && token.user.new_email?
        @user = token.user
        @user.email = @user.new_email
        @user.new_email = nil
        @user.email_valid = true
        gravatar_enabled = gravatar_enable(@user)
        if @user.save
          flash[:notice] = if gravatar_enabled
                             t("user.confirm_email.success") + " " + gravatar_status_message(@user)
                           else
                             t("user.confirm_email.success")
                           end
        else
          flash[:errors] = @user.errors
        end
        token.destroy
        session[:user] = @user.id
        redirect_to :action => "account", :display_name => @user.display_name
      elsif token
        flash[:error] = t "user.confirm_email.failure"
        redirect_to :action => "account", :display_name => token.user.display_name
      else
        flash[:error] = t "user.confirm_email.unknown_token"
      end
    end
  end

  def api_read
    if @this_user.visible?
      render :action => :api_read, :content_type => "text/xml"
    else
      render :text => "", :status => :gone
    end
  end

  def api_details
    @this_user = @user
    render :action => :api_read, :content_type => "text/xml"
  end

  def api_gpx_files
    doc = OSM::API.new.get_xml_doc
    @user.traces.reload.each do |trace|
      doc.root << trace.to_xml_node
    end
    render :text => doc.to_s, :content_type => "text/xml"
  end

  def view
    @this_user = User.find_by_display_name(params[:display_name])

    if @this_user &&
       (@this_user.visible? || (@user && @user.administrator?))
      @title = @this_user.display_name
    else
      render_unknown_user params[:display_name]
    end
  end

  def make_friend
    @new_friend = User.find_by_display_name(params[:display_name])

    if @new_friend
      if request.post?
        friend = Friend.new
        friend.user_id = @user.id
        friend.friend_user_id = @new_friend.id
        if @user.is_friends_with?(@new_friend)
          flash[:warning] = t "user.make_friend.already_a_friend", :name => @new_friend.display_name
        elsif friend.save
          flash[:notice] = t "user.make_friend.success", :name => @new_friend.display_name
          Notifier.friend_notification(friend).deliver_now
        else
          friend.add_error(t("user.make_friend.failed", :name => @new_friend.display_name))
        end

        if params[:referer]
          redirect_to params[:referer]
        else
          redirect_to :action => "view"
        end
      end
    else
      render_unknown_user params[:display_name]
    end
  end

  def remove_friend
    @friend = User.find_by_display_name(params[:display_name])

    if @friend
      if request.post?
        if @user.is_friends_with?(@friend)
          Friend.delete_all "user_id = #{@user.id} AND friend_user_id = #{@friend.id}"
          flash[:notice] = t "user.remove_friend.success", :name => @friend.display_name
        else
          flash[:error] = t "user.remove_friend.not_a_friend", :name => @friend.display_name
        end

        if params[:referer]
          redirect_to params[:referer]
        else
          redirect_to :action => "view"
        end
      end
    else
      render_unknown_user params[:display_name]
    end
  end

  ##
  # sets a user's status
  def set_status
    @this_user.status = params[:status]
    @this_user.save
    redirect_to :action => "view", :display_name => params[:display_name]
  end

  ##
  # delete a user, marking them as deleted and removing personal data
  def delete
    @this_user.delete
    redirect_to :action => "view", :display_name => params[:display_name]
  end

  ##
  # display a list of users matching specified criteria
  def list
    if request.post?
      ids = params[:user].keys.collect(&:to_i)

      User.where(:id => ids).update_all(:status => "confirmed") if params[:confirm]
      User.where(:id => ids).update_all(:status => "deleted") if params[:hide]

      redirect_to url_for(:status => params[:status], :ip => params[:ip], :page => params[:page])
    else
      conditions = {}
      conditions[:status] = params[:status] if params[:status]
      conditions[:creation_ip] = params[:ip] if params[:ip]

      @user_pages, @users = paginate(:users,
                                     :conditions => conditions,
                                     :order => :id,
                                     :per_page => 50)
    end
  end

  ##
  # omniauth success callback
  def auth_success
    auth_info = env["omniauth.auth"]

    provider = auth_info[:provider]
    uid = auth_info[:uid]
    name = auth_info[:info][:name]
    email = auth_info[:info][:email]

    case provider
    when "openid"
      email_verified = uid.match(%r{https://www.google.com/accounts/o8/id?(.*)}) ||
                       uid.match(%r{https://me.yahoo.com/(.*)})
    when "google", "facebook"
      email_verified = true
    else
      email_verified = false
    end

    if settings = session.delete(:new_user_settings)
      @user.auth_provider = provider
      @user.auth_uid = uid

      update_user(@user, settings)

      session[:user_errors] = @user.errors.as_json

      redirect_to :action => "account", :display_name => @user.display_name
    elsif session[:new_user]
      session[:new_user].auth_provider = provider
      session[:new_user].auth_uid = uid

      if email_verified && email == session[:new_user].email
        session[:new_user].status = "active"
      end

      redirect_to :action => "terms"
    else
      user = User.find_by_auth_provider_and_auth_uid(provider, uid)

      if user.nil? && provider == "google"
        openid_url = auth_info[:extra][:id_info]["openid_id"]
        user = User.find_by_auth_provider_and_auth_uid("openid", openid_url) if openid_url
        user.update(:auth_provider => provider, :auth_uid => uid) if user
      end

      if user
        case user.status
        when "pending" then
          unconfirmed_login(user)
        when "active", "confirmed" then
          successful_login(user, env["omniauth.params"]["referer"])
        when "suspended" then
          failed_login t("user.login.account is suspended", :webmaster => "mailto:#{SUPPORT_EMAIL}")
        else
          failed_login t("user.login.auth failure")
        end
      else
        redirect_to :action => "new", :nickname => name, :email => email,
                    :auth_provider => provider, :auth_uid => uid
      end
    end
  end

  ##
  # omniauth failure callback
  def auth_failure
    flash[:error] = t("user.auth_failure." + params[:message])
    redirect_to params[:origin] || login_url
  end

  private

  ##
  # handle password authentication
  def password_authentication(username, password)
    if user = User.authenticate(:username => username, :password => password)
      successful_login(user)
    elsif user = User.authenticate(:username => username, :password => password, :pending => true)
      unconfirmed_login(user)
    elsif User.authenticate(:username => username, :password => password, :suspended => true)
      failed_login t("user.login.account is suspended", :webmaster => "mailto:#{SUPPORT_EMAIL}"), username
    else
      failed_login t("user.login.auth failure"), username
    end
  end

  ##
  # return the URL to use for authentication
  def auth_url(provider, uid, referer = nil)
    params = { :provider => provider }

    params[:openid_url] = openid_expand_url(uid) if provider == "openid"

    if referer.nil?
      params[:origin] = request.path
    else
      params[:origin] = request.path + "?referer=" + CGI.escape(referer)
      params[:referer] = referer
    end

    auth_path(params)
  end

  ##
  # special case some common OpenID providers by applying heuristics to
  # try and come up with the correct URL based on what the user entered
  def openid_expand_url(openid_url)
    if openid_url.nil?
      return nil
    elsif openid_url.match(%r{(.*)gmail.com(/?)$}) || openid_url.match(%r{(.*)googlemail.com(/?)$})
      # Special case gmail.com as it is potentially a popular OpenID
      # provider and, unlike yahoo.com, where it works automatically, Google
      # have hidden their OpenID endpoint somewhere obscure this making it
      # somewhat less user friendly.
      return "https://www.google.com/accounts/o8/id"
    else
      return openid_url
    end
  end

  ##
  # process a successful login
  def successful_login(user, referer = nil)
    session[:user] = user.id
    session_expires_after 28.days if session[:remember_me]

    target = referer || session[:referer] || url_for(:controller => :site, :action => :index)

    # The user is logged in, so decide where to send them:
    #
    # - If they haven't seen the contributor terms, send them there.
    # - If they have a block on them, show them that.
    # - If they were referred to the login, send them back there.
    # - Otherwise, send them to the home page.
    if REQUIRE_TERMS_SEEN && !user.terms_seen
      redirect_to :action => :terms, :referer => target
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

    redirect_to :action => "login", :referer => session[:referer],
                :username => username, :remember_me => session[:remember_me]

    session.delete(:remember_me)
    session.delete(:referer)
  end

  ##
  #
  def unconfirmed_login(user)
    session[:token] = user.tokens.create.token

    redirect_to :action => "confirm", :display_name => user.display_name

    session.delete(:remember_me)
    session.delete(:referer)
  end

  ##
  # update a user's details
  def update_user(user, params)
    user.display_name = params[:user][:display_name]
    user.new_email = params[:user][:new_email]

    unless params[:user][:pass_crypt].empty? && params[:user][:pass_crypt_confirmation].empty?
      user.pass_crypt = params[:user][:pass_crypt]
      user.pass_crypt_confirmation = params[:user][:pass_crypt_confirmation]
    end

    if params[:user][:description] != user.description
      user.description = params[:user][:description]
      user.description_format = "markdown"
    end

    user.languages = params[:user][:languages].split(",")

    case params[:image_action]
    when "new" then
      user.image = params[:user][:image]
      user.image_use_gravatar = false
    when "delete" then
      user.image = nil
      user.image_use_gravatar = false
    when "gravatar" then
      user.image = nil
      user.image_use_gravatar = true
    end

    user.home_lat = params[:user][:home_lat]
    user.home_lon = params[:user][:home_lon]

    user.preferred_editor = if params[:user][:preferred_editor] == "default"
                              nil
                            else
                              params[:user][:preferred_editor]
                            end

    if params[:user][:auth_provider].nil? || params[:user][:auth_provider].blank?
      user.auth_provider = nil
      user.auth_uid = nil
    end

    if user.save
      set_locale

      if user.new_email.blank? || user.new_email == user.email
        flash.now[:notice] = t "user.account.flash update success"
      else
        user.email = user.new_email

        if user.valid?
          flash.now[:notice] = t "user.account.flash update success confirm needed"

          begin
            Notifier.email_confirm(user, user.tokens.create).deliver_now
          rescue
            # Ignore errors sending email
          end
        else
          @user.errors.set(:new_email, @user.errors.get(:email))
          @user.errors.set(:email, [])
        end

        user.restore_email!
      end
    end
  end

  ##
  # require that the user is a administrator, or fill out a helpful error message
  # and return them to the user page.
  def require_administrator
    if @user && !@user.administrator?
      flash[:error] = t("user.filter.not_an_administrator")

      if params[:display_name]
        redirect_to :action => "view", :display_name => params[:display_name]
      else
        redirect_to :action => "login", :referer => request.fullpath
      end
    elsif !@user
      redirect_to :action => "login", :referer => request.fullpath
    end
  end

  ##
  # require that the user in the URL is the logged in user
  def require_self
    if params[:display_name] != @user.display_name
      render :text => "", :status => :forbidden
    end
  end

  ##
  # ensure that there is a "this_user" instance variable
  def lookup_user_by_id
    @this_user = User.find(params[:id])
  end

  ##
  # ensure that there is a "this_user" instance variable
  def lookup_user_by_name
    @this_user = User.find_by_display_name(params[:display_name])
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => "view", :display_name => params[:display_name] unless @this_user
  end

  ##
  #
  def disable_terms_redirect
    # this is necessary otherwise going to the user terms page, when
    # having not agreed already would cause an infinite redirect loop.
    # it's .now so that this doesn't propagate to other pages.
    flash.now[:skip_terms] = true
  end

  ##
  # return permitted user parameters
  def user_params
    params.require(:user).permit(:email, :email_confirmation, :display_name,
                                 :auth_provider, :auth_uid,
                                 :pass_crypt, :pass_crypt_confirmation)
  end

  ##
  # check signup acls
  def check_signup_allowed(email = nil)
    domain = if email.nil?
               nil
             else
               email.split("@").last
             end

    if blocked = Acl.no_account_creation(request.remote_ip, domain)
      logger.info "Blocked signup from #{request.remote_ip} for #{email}"

      render :action => "blocked"
    end

    !blocked
  end

  ##
  # check if this user has a gravatar and set the user pref is true
  def gravatar_enable(user)
    # code from example https://en.gravatar.com/site/implement/images/ruby/
    return false if user.image.present?
    hash = Digest::MD5.hexdigest(user.email.downcase)
    url = "https://www.gravatar.com/avatar/#{hash}?d=404" # without d=404 we will always get an image back
    response = OSM.http_client.get(URI.parse(url))
    oldsetting = user.image_use_gravatar
    user.image_use_gravatar = response.success?
    oldsetting != user.image_use_gravatar
  end

  ##
  # display a message about th current status of the gravatar setting
  def gravatar_status_message(user)
    if user.image_use_gravatar
      return t "user.account.gravatar.enabled"
    else
      return t "user.account.gravatar.disabled"
    end
  end
end
