class UserController < ApplicationController
  layout 'site'

  before_filter :authorize, :only => [:api_details, :api_gpx_files]
  before_filter :authorize_web, :except => [:api_details, :api_gpx_files]
  before_filter :set_locale, :except => [:api_details, :api_gpx_files]
  before_filter :require_user, :only => [:set_home, :account, :go_public, :make_friend, :remove_friend, :upload_image, :delete_image]
  before_filter :check_database_readable, :except => [:api_details, :api_gpx_files]
  before_filter :check_database_writable, :only => [:login, :new, :set_home, :account, :go_public, :make_friend, :remove_friend, :upload_image, :delete_image]
  before_filter :check_api_readable, :only => [:api_details, :api_gpx_files]

  filter_parameter_logging :password, :pass_crypt, :pass_crypt_confirmation

  def save
    @title = 'create account'

    if Acl.find_by_address(request.remote_ip, :conditions => {:k => "no_account_creation"})
      render :action => 'new'
    else
      @user = User.new(params[:user])

      @user.visible = true
      @user.data_public = true
      @user.description = "" if @user.description.nil?
      @user.creation_ip = request.remote_ip
      @user.languages = request.user_preferred_languages

      if @user.save
        flash[:notice] = I18n.t('user.new.flash create success message')
        Notifier.deliver_signup_confirm(@user, @user.tokens.create)
        redirect_to :action => 'login'
      else
        render :action => 'new'
      end
    end
  end

  def account
    @title = 'edit account'
    if params[:user] and params[:user][:display_name] and params[:user][:description]
      if params[:user][:email] != @user.email
        @user.new_email = params[:user][:email]
      end

      @user.display_name = params[:user][:display_name]

      if params[:user][:pass_crypt].length > 0 or params[:user][:pass_crypt_confirmation].length > 0
        @user.pass_crypt = params[:user][:pass_crypt]
        @user.pass_crypt_confirmation = params[:user][:pass_crypt_confirmation]
      end

      @user.description = params[:user][:description]
      @user.home_lat = params[:user][:home_lat]
      @user.home_lon = params[:user][:home_lon]

      if @user.save
        if params[:user][:email] == @user.new_email
          flash[:notice] = I18n.t('user.account.flash update success confirm needed')
          Notifier.deliver_email_confirm(@user, @user.tokens.create)
        else
          flash[:notice] = I18n.t('user.account.flash update success')
        end
      end
    end
  end

  def set_home
    if params[:user][:home_lat] and params[:user][:home_lon]
      @user.home_lat = params[:user][:home_lat].to_f
      @user.home_lon = params[:user][:home_lon].to_f
      if @user.save
        flash[:notice] = I18n.t('user.set_home.flash success')
        redirect_to :controller => 'user', :action => 'account'
      end
    end
  end

  def go_public
    @user.data_public = true
    @user.save
    flash[:notice] = I18n.t('user.go_public.flash success')
    redirect_to :controller => 'user', :action => 'account', :display_name => @user.display_name
  end

  def lost_password
    @title = I18n.t('user.lost_password.title')
    if params[:user] and params[:user][:email]
      user = User.find_by_email(params[:user][:email], :conditions => {:visible => true})

      if user
        token = user.tokens.create
        Notifier.deliver_lost_password(user, token)
        flash[:notice] = I18n.t('user.lost_password.notice.email on way')
      else
        flash[:notice] = I18n.t('user.lost_password.notice email cannot find')
      end
    end
  end

  def reset_password
    @title = I18n.t('user.reset_password.title')
    if params['token']
      token = UserToken.find_by_token(params[:token])
      if token
        pass = OSM::make_token(8)
        user = token.user
        user.pass_crypt = pass
        user.pass_crypt_confirmation = pass
        user.active = true
        user.email_valid = true
        user.save!
        token.destroy
        Notifier.deliver_reset_password(user, pass)
        flash[:notice] = I18n.t('user.reset_password.flash changed check mail')
      else
        flash[:notice] = I18n.t('user.reset_password.flash token bad')
      end
    end

    redirect_to :action => 'login'
  end

  def new
    @title = 'create account'
    # The user is logged in already, so don't show them the signup page, instead
    # send them to the home page
    redirect_to :controller => 'site', :action => 'index' if session[:user]
  end

  def login
    if session[:user]
      # The user is logged in already, if the referer param exists, redirect them to that
      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :controller => 'site', :action => 'index'
      end
      return
    end
    @title = 'login'
    if params[:user]
      email_or_display_name = params[:user][:email]
      pass = params[:user][:password]
      user = User.authenticate(:username => email_or_display_name, :password => pass)
      if user
        session[:user] = user.id
        if params[:referer]
          redirect_to params[:referer]
        else
          redirect_to :controller => 'site', :action => 'index'
        end
        return
      elsif User.authenticate(:username => email_or_display_name, :password => pass, :inactive => true)
        @notice = "Sorry, your account is not active yet.<br>Please click on the link in the account confirmation email to activate your account."
      else
        @notice = "Sorry, couldn't log in with those details."
      end
    end
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
        token.destroy
        flash[:notice] = 'Confirmed your account, thanks for signing up!'
        session[:user] = @user.id
        redirect_to :action => 'account', :display_name => @user.display_name
      else
        @notice = 'Something went wrong confirming that user.'
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
        @user.save!
        token.destroy
        flash[:notice] = 'Confirmed your email address, thanks for signing up!'
        session[:user] = @user.id
        redirect_to :action => 'account', :display_name => @user.display_name
      else
        @notice = 'Something went wrong confirming that email address.'
      end
    end
  end

  def upload_image
    @user.image = params[:user][:image]
    @user.save!
    redirect_to :controller => 'user', :action => 'view', :display_name => @user.display_name
  end

  def delete_image
    @user.image = nil
    @user.save!
    redirect_to :controller => 'user', :action => 'view', :display_name => @user.display_name
  end

  def api_details
    render :text => @user.to_xml.to_s, :content_type => "text/xml"
  end

  def api_gpx_files
    doc = OSM::API.new.get_xml_doc
    @user.traces.each do |trace|
      doc.root << trace.to_xml_node() if trace.public? or trace.user == @user
    end
    render :text => doc.to_s, :content_type => "text/xml"
  end

  def view
    @this_user = User.find_by_display_name(params[:display_name], :conditions => {:visible => true})

    if @this_user
      @title = @this_user.display_name
    else
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
          flash[:notice] = "#{name} is now your friend."
          Notifier.deliver_friend_notification(friend)
        else
          friend.add_error("Sorry, failed to add #{name} as a friend.")
        end
      else
        flash[:notice] = "You are already friends with #{name}."  
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
        flash[:notice] = "#{friend.display_name} was removed from your friends."
      else
        flash[:notice] = "#{friend.display_name} is not one of your friends."
      end

      redirect_to :controller => 'user', :action => 'view'
    end
  end
end
