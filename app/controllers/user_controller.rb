class UserController < ApplicationController
  layout :choose_layout

  skip_before_filter :verify_authenticity_token, :only => [:api_details, :api_gpx_files]
  before_filter :disable_terms_redirect, :only => [:terms, :save, :logout, :api_details]
  before_filter :authorize, :only => [:api_details, :api_gpx_files]
  before_filter :authorize_web, :except => [:api_details, :api_gpx_files]
  before_filter :set_locale, :except => [:api_details, :api_gpx_files]
  before_filter :require_user, :only => [:account, :go_public, :make_friend, :remove_friend]
  before_filter :check_database_readable, :except => [:api_details, :api_gpx_files]
  before_filter :check_database_writable, :only => [:login, :new, :account, :go_public, :make_friend, :remove_friend]
  before_filter :check_api_readable, :only => [:api_details, :api_gpx_files]
  before_filter :require_allow_read_prefs, :only => [:api_details]
  before_filter :require_allow_read_gpx, :only => [:api_gpx_files]
  before_filter :require_cookies, :only => [:login, :confirm]
  before_filter :require_administrator, :only => [:set_status, :delete, :list]
  before_filter :lookup_this_user, :only => [:set_status, :delete]

  cache_sweeper :user_sweeper, :only => [:account, :set_status, :delete]

  def terms
    @legale = params[:legale] || OSM.IPToCountry(request.remote_ip) || DEFAULT_LEGALE
    @text = OSM.legal_text_for_country(@legale)

    if request.xhr?
      render :partial => "terms"
    elsif using_open_id?
      # The redirect from the OpenID provider reenters here
      # again and we need to pass the parameters through to
      # the open_id_authentication function
      @user = session.delete(:new_user)

      openid_verify(nil, @user) do |user|
      end

      if @user.openid_url.nil? or @user.invalid?
        render :action => 'new'
      else
        render :action => 'terms'
      end
    else
      session[:referer] = params[:referer]

      @title = t 'user.terms.title'
      @user = User.new(params[:user]) if params[:user]

      if params[:user] and params[:user][:openid_url] and @user.pass_crypt.empty?
        # We are creating an account with OpenID and no password
        # was specified so create a random one
        @user.pass_crypt = SecureRandom.base64(16) 
        @user.pass_crypt_confirmation = @user.pass_crypt 
      end

      if @user
        if @user.invalid?
          if @user.new_record?
            # Something is wrong with a new user, so rerender the form
            render :action => :new
          else
            # Error in existing user, so go to account settings
            flash[:errors] = @user.errors
            redirect_to :action => :account, :display_name => @user.display_name
          end
        elsif @user.terms_agreed?
          # Already agreed to terms, so just show settings
          redirect_to :action => :account, :display_name => @user.display_name
        elsif params[:user] and params[:user][:openid_url] and not params[:user][:openid_url].empty?
          # Verify OpenID before moving on
          session[:new_user] = @user
          openid_verify(params[:user][:openid_url], @user)
        end
      else
        # Not logged in, so redirect to the login page
        redirect_to :action => :login, :referer => request.fullpath
      end
    end
  end

  def save
    @title = t 'user.new.title'

    if Acl.address(request.remote_ip).where(:k => "no_account_creation").exists?
      render :action => 'new'
    elsif params[:decline]
      if @user
        @user.terms_seen = true

        if @user.save
          flash[:notice] = t 'user.new.terms declined', :url => t('user.new.terms declined url')
        end

        if params[:referer]
          redirect_to params[:referer]
        else
          redirect_to :action => :account, :display_name => @user.display_name
        end
      else
        redirect_to t('user.terms.declined')
      end
    elsif @user
      if !@user.terms_agreed?
        @user.consider_pd = params[:user][:consider_pd]
        @user.terms_agreed = Time.now.getutc
        @user.terms_seen = true
        if @user.save
          flash[:notice] = t 'user.new.terms accepted'
        end
      end

      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :action => :account, :display_name => @user.display_name
      end
    else
      @user = User.new(params[:user])

      @user.status = "pending"
      @user.data_public = true
      @user.description = "" if @user.description.nil?
      @user.creation_ip = request.remote_ip
      @user.languages = request.user_preferred_languages
      @user.terms_agreed = Time.now.getutc
      @user.terms_seen = true
      @user.openid_url = nil if @user.openid_url and @user.openid_url.empty?
      
      if @user.save
        flash[:piwik_goal] = PIWIK_SIGNUP_GOAL if defined?(PIWIK_SIGNUP_GOAL)
        flash[:notice] = t 'user.new.flash create success message', :email => @user.email
        Notifier.signup_confirm(@user, @user.tokens.create(:referer => session.delete(:referer))).deliver
        session[:token] = @user.tokens.create.token
        redirect_to :action => 'login', :referer => params[:referer]
      else
        render :action => 'new', :referer => params[:referer]
      end
    end
  end

  def account
    @title = t 'user.account.title'
    @tokens = @user.oauth_tokens.authorized

    if params[:user] and params[:user][:display_name] and params[:user][:description]
      @user.display_name = params[:user][:display_name]
      @user.new_email = params[:user][:new_email]

      if params[:user][:pass_crypt].length > 0 or params[:user][:pass_crypt_confirmation].length > 0
        @user.pass_crypt = params[:user][:pass_crypt]
        @user.pass_crypt_confirmation = params[:user][:pass_crypt_confirmation]
      end

      @user.description = params[:user][:description]
      @user.languages = params[:user][:languages].split(",")

      case params[:image_action]
        when "new" then @user.image = params[:user][:image]
        when "delete" then @user.image = nil
      end

      @user.home_lat = params[:user][:home_lat]
      @user.home_lon = params[:user][:home_lon]

      if params[:user][:preferred_editor] == "default"
        @user.preferred_editor = nil
      else
        @user.preferred_editor = params[:user][:preferred_editor]
      end

      @user.openid_url = nil if params[:user][:openid_url].blank?

      if params[:user][:openid_url] and
         params[:user][:openid_url].length > 0 and
         params[:user][:openid_url] != @user.openid_url
        # If the OpenID has changed, we want to check that it is a
        # valid OpenID and one the user has control over before saving
        # it as a password equivalent for the user.
        session[:new_user] = @user
        openid_verify(params[:user][:openid_url], @user)
      else
        update_user(@user)
      end
    elsif using_open_id?
      # The redirect from the OpenID provider reenters here
      # again and we need to pass the parameters through to
      # the open_id_authentication function
      @user = session.delete(:new_user)
      openid_verify(nil, @user) do |user|
        update_user(user)
      end
    end
  end

  def go_public
    @user.data_public = true
    @user.save
    flash[:notice] = t 'user.go_public.flash success'
    redirect_to :controller => 'user', :action => 'account', :display_name => @user.display_name
  end

  def lost_password
    @title = t 'user.lost_password.title'

    if params[:user] and params[:user][:email]
      user = User.visible.find_by_email(params[:user][:email])

      if user.nil?
        users = User.visible.where("LOWER(email) = LOWER(?)", params[:user][:email])

        if users.count == 1
          user = users.first
        end
      end

      if user
        token = user.tokens.create
        Notifier.lost_password(user, token).deliver
        flash[:notice] = t 'user.lost_password.notice email on way'
        redirect_to :action => 'login'
      else
        flash.now[:error] = t 'user.lost_password.notice email cannot find'
      end
    end
  end

  def reset_password
    @title = t 'user.reset_password.title'

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
            flash[:notice] = t 'user.reset_password.flash changed'
            redirect_to :action => 'login'
          end
        end
      else
        flash[:error] = t 'user.reset_password.flash token bad'
        redirect_to :action => 'lost_password'
      end
    end
  end

  def new
    @title = t 'user.new.title'
    @referer = params[:referer] || session[:referer]

    if @user
      # The user is logged in already, so don't show them the signup
      # page, instead send them to the home page
      if @referer
        redirect_to @referer
      else
        redirect_to :controller => 'site', :action => 'index'
      end
    elsif params.key?(:openid)
      @user = User.new(:email => params[:email],
                       :email_confirmation => params[:email],
                       :display_name => params[:nickname],
                       :openid_url => params[:openid])

      flash.now[:notice] = t 'user.new.openid association'
    end
  end

  def login
    if params[:username] or using_open_id?
      session[:remember_me] ||= params[:remember_me]
      session[:referer] ||= params[:referer]

      if using_open_id?
        openid_authentication(params[:openid_url])
      else
        password_authentication(params[:username], params[:password])
      end
    elsif params[:notice]
      flash.now[:notice] = t "user.login.notice_#{params[:notice]}"
    elsif flash[:notice].nil?
      flash.now[:notice] =  t 'user.login.notice'
    end
  end

  def logout
    @title = t 'user.logout.title'

    if params[:session] == request.session_options[:id]
      if session[:token]
        token = UserToken.find_by_token(session[:token])
        if token
          token.destroy
        end
        session.delete(:token)
      end
      session.delete(:user)
      session_expires_automatically
      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :controller => 'site', :action => 'index'
      end
    end
  end

  def confirm
    if request.post?
      if token = UserToken.find_by_token(params[:confirm_string])
        if token.user.active?
          flash[:error] = t('user.confirm.already active')
          redirect_to :action => 'login'
        else
          user = token.user
          user.status = "active"
          user.email_valid = true
          user.save!
          referer = token.referer
          token.destroy

          if session[:token] 
            token = UserToken.find_by_token(session[:token])
            session.delete(:token)
          else
            token = nil
          end

          if token.nil? or token.user != user
            flash[:notice] = t('user.confirm.success')
            redirect_to :action => :login, :referer => referer
          else
            token.destroy

            session[:user] = user.id
            cookies.permanent["_osm_username"] = user.display_name

            if referer.nil?
              flash[:notice] = t('user.confirm.success') + "<br /><br />" + t('user.confirm.before you start')
              redirect_to :action => :account, :display_name => user.display_name
            else
              flash[:notice] = t('user.confirm.success')
              redirect_to referer
            end
          end
        end
      else
        user = User.find_by_display_name(params[:display_name])

        if user and user.active?
          flash[:error] = t('user.confirm.already active')
        elsif user
          flash[:error] = t('user.confirm.unknown token') + t('user.confirm.reconfirm', :reconfirm => url_for(:action => 'confirm_resend', :display_name => params[:display_name]))
        else
          flash[:error] = t('user.confirm.unknown token')
        end

        redirect_to :action => 'login'
      end
    end
  end

  def confirm_resend
    if user = User.find_by_display_name(params[:display_name])
      Notifier.signup_confirm(user, user.tokens.create).deliver
      flash[:notice] = t 'user.confirm_resend.success', :email => user.email
    else
      flash[:notice] = t 'user.confirm_resend.failure', :name => params[:display_name]
    end

    redirect_to :action => 'login'
  end

  def confirm_email
    if request.post?
      token = UserToken.find_by_token(params[:confirm_string])
      if token and token.user.new_email?
        @user = token.user
        @user.email = @user.new_email
        @user.new_email = nil
        @user.email_valid = true
        if @user.save
          flash[:notice] = t 'user.confirm_email.success'
        else
          flash[:errors] = @user.errors
        end
        token.destroy
        session[:user] = @user.id
        cookies.permanent["_osm_username"] = @user.display_name
        redirect_to :action => 'account', :display_name => @user.display_name
      else
        flash[:error] = t 'user.confirm_email.failure'
        redirect_to :action => 'account', :display_name => @user.display_name
      end
    end
  end

  def api_gpx_files
    doc = OSM::API.new.get_xml_doc
    @user.traces.each do |trace|
      doc.root << trace.to_xml_node() if trace.public? or trace.user == @user
    end
    render :text => doc.to_s, :content_type => "text/xml"
  end

  def view
    @this_user = User.find_by_display_name(params[:display_name])

    if @this_user and
       (@this_user.visible? or (@user and @user.administrator?))
      @title = @this_user.display_name
    else
      @title = t 'user.no_such_user.title'
      @not_found_user = params[:display_name]
      render :action => 'no_such_user', :status => :not_found
    end
  end

  def make_friend
    if params[:display_name]
      name = params[:display_name]
      new_friend = User.active.where(:display_name => name).first
      friend = Friend.new
      friend.user_id = @user.id
      friend.friend_user_id = new_friend.id
      unless @user.is_friends_with?(new_friend)
        if friend.save
          flash[:notice] = t 'user.make_friend.success', :name => name
          Notifier.friend_notification(friend).deliver
        else
          friend.add_error(t('user.make_friend.failed', :name => name))
        end
      else
        flash[:warning] = t 'user.make_friend.already_a_friend', :name => name
      end

      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :controller => 'user', :action => 'view'
      end
    end
  end

  def remove_friend
    if params[:display_name]
      name = params[:display_name]
      friend = User.active.where(:display_name => name).first
      if @user.is_friends_with?(friend)
        Friend.delete_all "user_id = #{@user.id} AND friend_user_id = #{friend.id}"
        flash[:notice] = t 'user.remove_friend.success', :name => friend.display_name
      else
        flash[:error] = t 'user.remove_friend.not_a_friend', :name => friend.display_name
      end

      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :controller => 'user', :action => 'view'
      end
    end
  end

  ##
  # sets a user's status
  def set_status
    @this_user.update_attributes(:status => params[:status])
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end

  ##
  # delete a user, marking them as deleted and removing personal data
  def delete
    @this_user.delete
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end

  ##
  # display a list of users matching specified criteria
  def list
    if request.post?
      ids = params[:user].keys.collect { |id| id.to_i }

      User.update_all("status = 'confirmed'", :id => ids) if params[:confirm]
      User.update_all("status = 'deleted'", :id => ids) if params[:hide]

      redirect_to url_for(:status => params[:status], :ip => params[:ip], :page => params[:page])
    else
      conditions = Hash.new
      conditions[:status] = params[:status] if params[:status]
      conditions[:creation_ip] = params[:ip] if params[:ip]

      @user_pages, @users = paginate(:users,
                                     :conditions => conditions,
                                     :order => :id,
                                     :per_page => 50)
    end
  end

private

  ##
  # handle password authentication
  def password_authentication(username, password)
    if user = User.authenticate(:username => username, :password => password)
      successful_login(user)
    elsif user = User.authenticate(:username => username, :password => password, :pending => true)
      failed_login t('user.login.account not active', :reconfirm => url_for(:action => 'confirm_resend', :display_name => user.display_name))
    elsif User.authenticate(:username => username, :password => password, :suspended => true)
      failed_login t('user.login.account is suspended', :webmaster => "mailto:webmaster@openstreetmap.org")
    else
      failed_login t('user.login.auth failure')
    end
  end

  ##
  # handle OpenID authentication
  def openid_authentication(openid_url)
    # If we don't appear to have a user for this URL then ask the
    # provider for some extra information to help with signup
    if openid_url and User.find_by_openid_url(openid_url)
      required = nil
    else
      required = [:nickname, :email, "http://axschema.org/namePerson/friendly", "http://axschema.org/contact/email"]
    end

    # Start the authentication
    authenticate_with_open_id(openid_expand_url(openid_url), :method => :get, :required => required) do |result, identity_url, sreg, ax|
      if result.successful?
        # We need to use the openid url passed back from the OpenID provider
        # rather than the one supplied by the user, as these can be different.
        #
        # For example, you can simply enter yahoo.com in the login box rather
        # than a user specific url. Only once it comes back from the provider
        # provider do we know the unique address for the user.
        if user = User.find_by_openid_url(identity_url)
          case user.status
            when "pending" then
              failed_login t('user.login.account not active')
            when "active", "confirmed" then
              successful_login(user)
            when "suspended" then
              failed_login t('user.login.account is suspended', :webmaster => "mailto:webmaster@openstreetmap.org")
            else
              failed_login t('user.login.auth failure')
          end
        else
          # Guard against not getting any extension data
          sreg = Hash.new if sreg.nil?
          ax = Hash.new if ax.nil?

          # We don't have a user registered to this OpenID, so redirect
          # to the create account page with username and email filled
          # in if they have been given by the OpenID provider through
          # the simple registration protocol.
          nickname = sreg["nickname"] || ax["http://axschema.org/namePerson/friendly"]
          email = sreg["email"] || ax["http://axschema.org/contact/email"]
          redirect_to :controller => 'user', :action => 'new', :nickname => nickname, :email => email, :openid => identity_url
        end
      elsif result.missing?
        failed_login t('user.login.openid missing provider')
      elsif result.invalid?
        failed_login t('user.login.openid invalid')
      else
        failed_login t('user.login.auth failure')
      end
    end
  end

  ##
  # verify an OpenID URL
  def openid_verify(openid_url, user)
    user.openid_url = openid_url

    authenticate_with_open_id(openid_expand_url(openid_url), :method => :get) do |result, identity_url|
      if result.successful?
        # We need to use the openid url passed back from the OpenID provider
        # rather than the one supplied by the user, as these can be different.
        #
        # For example, you can simply enter yahoo.com in the login box rather
        # than a user specific url. Only once it comes back from the provider
        # provider do we know the unique address for the user.
        user.openid_url = identity_url
        yield user
      elsif result.missing?
        flash.now[:error] = t 'user.login.openid missing provider'
      elsif result.invalid?
        flash.now[:error] = t 'user.login.openid invalid'
      else
        flash.now[:error] = t 'user.login.auth failure'
      end
    end
  end

  ##
  # special case some common OpenID providers by applying heuristics to
  # try and come up with the correct URL based on what the user entered
  def openid_expand_url(openid_url)
    if openid_url.nil?
      return nil
    elsif openid_url.match(/(.*)gmail.com(\/?)$/) or openid_url.match(/(.*)googlemail.com(\/?)$/)
      # Special case gmail.com as it is potentially a popular OpenID
      # provider and, unlike yahoo.com, where it works automatically, Google
      # have hidden their OpenID endpoint somewhere obscure this making it
      # somewhat less user friendly.
      return 'https://www.google.com/accounts/o8/id'
    else
      return openid_url
    end
  end  

  ##
  # process a successful login
  def successful_login(user)
    cookies.permanent["_osm_username"] = user.display_name

    session[:user] = user.id
    session_expires_after 1.month if session[:remember_me]

    target = session[:referer] || url_for(:controller => :site, :action => :index)

    # The user is logged in, so decide where to send them:
    #
    # - If they haven't seen the contributor terms, send them there.
    # - If they have a block on them, show them that.
    # - If they were referred to the login, send them back there.
    # - Otherwise, send them to the home page.
    if REQUIRE_TERMS_SEEN and not user.terms_seen
      redirect_to :controller => :user, :action => :terms, :referer => target
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
  def failed_login(message)
    flash[:error] = message

    redirect_to :action => 'login', :referer =>  session[:referer]

    session.delete(:remember_me)
    session.delete(:referer)
  end

  ##
  # update a user's details
  def update_user(user)
    if user.save
      set_locale

      if user.new_email.blank?
        flash.now[:notice] = t 'user.account.flash update success'
      else
        user.email = user.new_email

        if user.valid?
          flash.now[:notice] = t 'user.account.flash update success confirm needed'

          begin
            Notifier.email_confirm(user, user.tokens.create).deliver
          rescue
            # Ignore errors sending email
          end
        else
          @user.errors.set(:new_email, @user.errors.get(:email))
          @user.errors.set(:email, [])
        end

        user.reset_email!
      end
    end
  end

  ##
  # require that the user is a administrator, or fill out a helpful error message
  # and return them to the user page.
  def require_administrator
    if @user and not @user.administrator?
      flash[:error] = t('user.filter.not_an_administrator')

      if params[:display_name]
        redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
      else
        redirect_to :controller => 'user', :action => 'login', :referer => request.fullpath
      end
    elsif not @user
      redirect_to :controller => 'user', :action => 'login', :referer => request.fullpath
    end
  end

  ##
  # ensure that there is a "this_user" instance variable
  def lookup_this_user
    @this_user = User.find_by_display_name(params[:display_name])
  rescue ActiveRecord::RecordNotFound
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name] unless @this_user
  end

  ##
  # Choose the layout to use. See
  # https://rails.lighthouseapp.com/projects/8994/tickets/5371-layout-with-onlyexcept-options-makes-other-actions-render-without-layouts
  def choose_layout
    oauth_url = url_for(:controller => :oauth, :action => :oauthorize, :only_path => true)

    if [ 'api_details' ].include? action_name
      nil
    elsif params[:referer] and URI.parse(params[:referer]).path == oauth_url
      'slim'
    else
      'site'
    end
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
