class UserController < ApplicationController
  layout 'site', :except => :api_details

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
  before_filter :require_administrator, :only => [:activate, :deactivate, :hide, :unhide, :delete]
  before_filter :lookup_this_user, :only => [:activate, :deactivate, :hide, :unhide, :delete]

  filter_parameter_logging :password, :pass_crypt, :pass_crypt_confirmation

  cache_sweeper :user_sweeper, :only => [:account, :hide, :unhide, :delete]

  def save
    @title = t 'user.new.title'

    if Acl.find_by_address(request.remote_ip, :conditions => {:k => "no_account_creation"})
      render :action => 'new'
    else
	  #The redirect from the OpenID provider reenters here again 
      #and we need to pass the parameters through to the  
      #open_id_authentication function a second time 
      if params[:open_id_complete] 
        openid_verify('', true) 
        #We have set the user.openid_url to nil beforehand. If it hasn't 
        #been set to a new valid openid_url, it means the openid couldn't be validated 
        if @user.nil? or @user.openid_url.nil? 
          render :action => 'new' 
          return 
        end   
      else
      @user = User.new(params[:user])

      @user.visible = true
      @user.data_public = true
      @user.description = "" if @user.description.nil?
      @user.creation_ip = request.remote_ip
      @user.languages = request.user_preferred_languages
        #Set the openid_url to nil as for one it is used 
        #to check if the openid could be validated and secondly 
        #to not get dupplicate conflicts for an empty openid  
        @user.openid_url = nil

if (!params[:user][:openid_url].nil? and params[:user][:openid_url].length > 0)
		  if @user.pass_crypt.length == 0 
            #if the password is empty, but we have a openid 
            #then generate a random passowrd to disable 
            #loging in via password 
            @user.pass_crypt = ActiveSupport::SecureRandom.base64(16) 
            @user.pass_crypt_confirmation = @user.pass_crypt 
          end
		  #Validate all of the other fields before
		  #redirecting to the openid provider
		  if !@user.valid?
			render :action => 'new'
		  else		  
			#TODO: Is it a problem to store the user variable with respect to password safty in the session variables?
			#Store the user variable in the session for it to be accessible when redirecting back from the openid provider
			session[:new_usr] = @user
			begin
			  @norm_openid_url = OpenIdAuthentication.normalize_identifier(params[:user][:openid_url])
			rescue
			  flash.now[:error] = t 'user.login.openid invalid'
			  render :action => 'new'
			  return
			end
			#Verify that the openid provided is valid and that the user is the owner of the id
			openid_verify(@norm_openid_url, true)
			#openid_verify can return in two ways:
			#Either it returns with a redirect to the openid provider who then freshly
			#redirects back to this url if the openid is valid, or if the openid is not plausible
			#and no provider for it could be found it just returns
			#we want to just let the redirect through
			if response.headers["Location"].nil?
			  render :action => 'new'
			end
		  end
		  #At this point there was either an error and the page has been rendered,
		  #or there is a redirect to the openid provider and the rest of the method
		  #gets executed whenn this method gets reentered after redirecting back
		  #from the openid provider
		  return
		end
	  end

      if @user.save
        flash[:notice] = t 'user.new.flash create success message'
        Notifier.deliver_signup_confirm(@user, @user.tokens.create(:referer => params[:referer]))
        redirect_to :action => 'login'
      else
        render :action => 'new'
      end
    end
  end

  def account
    @title = t 'user.account.title'
    @tokens = @user.oauth_tokens.find :all, :conditions => 'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'

	#The redirect from the OpenID provider reenters here again
    #and we need to pass the parameters through to the 
    #open_id_authentication function
    if params[:open_id_complete]
      openid_verify('', false)
	  @user.save
      return
    end

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

      if @user.save
        set_locale

        if @user.new_email.nil? or @user.new_email.empty?
          flash.now[:notice] = t 'user.account.flash update success'
        else
          flash.now[:notice] = t 'user.account.flash update success confirm needed'

          begin
            Notifier.deliver_email_confirm(@user, @user.tokens.create)
          rescue
            # Ignore errors sending email
          end
        end
      end

	  if (params[:user][:openid_url].length > 0)
		begin
		  @norm_openid_url = OpenIdAuthentication.normalize_identifier(params[:user][:openid_url])
		  if (@norm_openid_url != @user.openid_url)
			#If the OpenID has changed, we want to check that it is a valid OpenID and one
			#the user has control over before saving the openID as a password equivalent for
			#the user.
			openid_verify(@norm_openid_url, false)
		  end
		rescue
		  flash.now[:error] = t 'user.login.openid invalid'
		end
      end

    else
      if flash[:errors]
        flash[:errors].each do |attr,msg|
          attr = "new_email" if attr == "email"
          @user.errors.add(attr,msg)
        end
      end
    end
  end

  def openid_specialcase_mapping(openid_url)
    #Special case gmail.com, as it is pontentially a popular OpenID provider and unlike
    #yahoo.com, where it works automatically, Google have hidden their OpenID endpoint
    #somewhere obscure making it less userfriendly.
    if (openid_url.match(/(.*)gmail.com(\/?)$/) or openid_url.match(/(.*)googlemail.com(\/?)$/) )
      return 'https://www.google.com/accounts/o8/id'
    end

    return nil
  end  

  def openid_verify(openid_url,account_create)
    authenticate_with_open_id(openid_url) do |result, identity_url|
      if result.successful?
        #We need to use the openid url passed back from the OpenID provider
        #rather than the one supplied by the user, as these can be different.
        #e.g. one can simply enter yahoo.com in the login box, i.e. no user specific url
        #only once it comes back from the OpenID provider do we know the unique address for
        #the user.
		@user = session[:new_usr] unless @user #this is used for account creation when the user is not yet in the database
        @user.openid_url = identity_url
	  elsif result.missing?
		mapped_id = openid_specialcase_mapping(openid_url)
		if mapped_id
		  openid_verify(mapped_id, account_create)
		else
		  flash.now[:error] = t 'user.login.openid missing provider'
		end
	  elsif result.invalid?
		flash.now[:error] = t 'user.login.openid invalid'
	  else
		flash.now[:error] = t 'user.login.auth failure'
	  end
    end
  end

  def open_id_authentication(openid_url)
    #TODO: only ask for nickname and email, if we don't already have a user for that openID, in which case
    #email and nickname are already filled out. I don't know how to do that with ruby syntax though, as we
    #don't want to duplicate the do block
    #On the other hand it also doesn't matter too much if we ask every time, as the OpenID provider should
    #remember these results, and shouldn't repromt the user for these data each time.
    authenticate_with_open_id(openid_url, :return_to => request.protocol + request.host_with_port + '/login?referer=' + params[:referer], :optional => [:nickname, :email]) do |result, identity_url, registration|
      if result.successful?
        #We need to use the openid url passed back from the OpenID provider
        #rather than the one supplied by the user, as these can be different.
        #e.g. one can simply enter yahoo.com in the login box, i.e. no user specific url
        #only once it comes back from the OpenID provider do we know the unique address for
        #the user.
        user = User.find_by_openid_url(identity_url)
        if user
          if user.visible? and user.active?
            session[:user] = user.id
			session_expires_after 1.month if session[:remember]
          else
            user = nil
            flash.now[:error] = t 'user.login.account not active'
          end
        else
          #We don't have a user registered to this OpenID. Redirect to the create account page
          #with username and email filled in if they have been given by the OpenID provider through
          #the simple registration protocol
          redirect_to :controller => 'user', :action => 'new', :nickname => registration['nickname'], :email => registration['email'], :openid => identity_url
        end
      else if result.missing?
             #Try and apply some heuristics to make common cases more userfriendly
             mapped_id = openid_specialcase_mapping(openid_url)
             if mapped_id
               open_id_authentication(mapped_id)
             else
               flash.now[:error] = t 'user.login.openid missing provider'
             end
           else if result.invalid?
                  flash.now[:error] = t 'user.login.openid invalid'
                else
                  flash.now[:error] = t 'user.login.auth failure'
                end
           end
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
      user = User.find_by_email(params[:user][:email], :conditions => {:visible => true})

      if user
        token = user.tokens.create
        Notifier.deliver_lost_password(user, token)
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
          @user.active = true
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

    # The user is logged in already, so don't show them the signup page, instead
    # send them to the home page
    redirect_to :controller => 'site', :action => 'index' if session[:user]

	@nickname = params['nickname']
    @email = params['email']
	@openID = params['openid']
  end

  def login

	#The redirect from the OpenID provider reenters here again
    #and we need to pass the parameters through to the 
    # open_id_authentication function
    if params[:open_id_complete]
      open_id_authentication('')
    end

    if params[:user] and session[:user].nil?
	  if !params[:user][:openid_url].nil? and !params[:user][:openid_url].empty?
		session[:remember] = params[:remember_me]
        open_id_authentication(params[:user][:openid_url])
      else
		email_or_display_name = params[:user][:email]
		pass = params[:user][:password]
		user = User.authenticate(:username => email_or_display_name, :password => pass)
		if user
		  session[:user] = user.id
		  session_expires_after 1.month if params[:remember_me]
		elsif User.authenticate(:username => email_or_display_name, :password => pass, :inactive => true)
		  flash.now[:error] = t 'user.login.account not active'
		else
		  flash.now[:error] = t 'user.login.auth failure'
		end
	  end
    end

    if session[:user]
      # The user is logged in, if the referer param exists, redirect them to that
      # unless they've also got a block on them, in which case redirect them to
      # the block so they can clear it.
      user = User.find(session[:user])
      block = user.blocked_on_view
      if block
        redirect_to block, :referrer => params[:referrer]
      elsif params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :controller => 'site', :action => 'index'
      end
      return
    end

    @title = t 'user.login.title'
  end

  def logout
    if session[:token]
      token = UserToken.find_by_token(session[:token])
      if token
        token.destroy
      end
      session[:token] = nil
    end
    session[:user] = nil
    session_expires_automatically
    if params[:referer]
      redirect_to params[:referer]
    else
      redirect_to :controller => 'site', :action => 'index'
    end
  end

  def confirm
    if params[:confirm_action]
      token = UserToken.find_by_token(params[:confirm_string])
      if token and !token.user.active?
        @user = token.user
        @user.active = true
        @user.email_valid = true
        @user.save!
        referer = token.referer
        token.destroy
        flash[:notice] = t 'user.confirm.success'
        session[:user] = @user.id
        unless referer.nil?
          redirect_to referer
        else
          redirect_to :action => 'account', :display_name => @user.display_name
        end
      else
        flash.now[:error] = t 'user.confirm.failure'
      end
    end
  end

  def confirm_email
    if params[:confirm_action]
      token = UserToken.find_by_token(params[:confirm_string])
      if token and token.user.new_email?
        @user = token.user
        @user.email = @user.new_email
        @user.new_email = nil
        @user.active = true
        @user.email_valid = true
        if @user.save
          flash[:notice] = t 'user.confirm_email.success'
        else
          flash[:errors] = @user.errors
        end
        token.destroy
        session[:user] = @user.id
        redirect_to :action => 'account', :display_name => @user.display_name
      else
        flash.now[:error] = t 'user.confirm_email.failure'
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
      new_friend = User.find_by_display_name(name, :conditions => {:visible => true})
      friend = Friend.new
      friend.user_id = @user.id
      friend.friend_user_id = new_friend.id
      unless @user.is_friends_with?(new_friend)
        if friend.save
          flash[:notice] = t 'user.make_friend.success', :name => name
          Notifier.deliver_friend_notification(friend)
        else
          friend.add_error(t('user.make_friend.failed', :name => name))
        end
      else
        flash[:warning] = t 'user.make_friend.already_a_friend', :name => name
      end

      redirect_to :controller => 'user', :action => 'view'
    end
  end

  def remove_friend
    if params[:display_name]
      name = params[:display_name]
      friend = User.find_by_display_name(name, :conditions => {:visible => true})
      if @user.is_friends_with?(friend)
        Friend.delete_all "user_id = #{@user.id} AND friend_user_id = #{friend.id}"
        flash[:notice] = t 'user.remove_friend.success', :name => friend.display_name
      else
        flash[:error] = t 'user.remove_friend.not_a_friend', :name => friend.display_name
      end

      redirect_to :controller => 'user', :action => 'view'
    end
  end

  ##
  # activate a user, allowing them to log in
  def activate
    @this_user.update_attributes(:active => true)
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end

  ##
  # deactivate a user, preventing them from logging in
  def deactivate
    @this_user.update_attributes(:active => false)
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end

  ##
  # hide a user, marking them as logically deleted
  def hide
    @this_user.update_attributes(:visible => false)
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end

  ##
  # unhide a user, clearing the logically deleted flag
  def unhide
    @this_user.update_attributes(:visible => true)
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end

  ##
  # delete a user, marking them as deleted and removing personal data
  def delete
    @this_user.delete
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
  end
private
  ##
  # require that the user is a administrator, or fill out a helpful error message
  # and return them to the user page.
  def require_administrator
    unless @user.administrator?
      flash[:error] = t('user.filter.not_an_administrator')
      redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
    end
  end

  ##
  # ensure that there is a "this_user" instance variable
  def lookup_this_user
    @this_user = User.find_by_display_name(params[:display_name])
  rescue ActiveRecord::RecordNotFound
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name] unless @this_user
  end
end
