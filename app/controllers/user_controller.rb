class UserController < ApplicationController
  layout 'site'

  before_filter :authorize, :only => [:api_details, :api_gpx_files]
  before_filter :authorize_web, :only => [:account, :go_public, :view, :diary, :make_friend, :remove_friend]
  before_filter :require_user, :only => [:set_home, :account, :go_public, :make_friend, :remove_friend]

  filter_parameter_logging :password, :pass_crypt, :pass_crypt_confirmation

  def save
    @title = 'create account'
    @user = User.new(params[:user])

    if @user.save
      token = @user.tokens.create
      flash[:notice] = "User was successfully created. Check your email for a confirmation note, and you\'ll be mapping in no time :-)<br>Please note that you won't be able to login until you've received and confirmed your email address."
      Notifier::deliver_signup_confirm(@user, token)
      redirect_to :action => 'login'
    else
      render :action => 'new'
    end
  end

  def account
    @title = 'edit account'
    if params[:user] and params[:user][:display_name] and params[:user][:description]
      home_lat =  params[:user][:home_lat]
      home_lon =  params[:user][:home_lon]

      @user.display_name = params[:user][:display_name]
      if params[:user][:pass_crypt].length > 0 or params[:user][:pass_crypt_confirmation].length > 0
        @user.pass_crypt = params[:user][:pass_crypt]
        @user.pass_crypt_confirmation = params[:user][:pass_crypt_confirmation]
      end
      @user.description = params[:user][:description]
      @user.home_lat = home_lat
      @user.home_lon = home_lon
      if @user.save
        flash[:notice] = "User information updated successfully."
      else
        flash.delete(:notice)
      end
    end
  end

  def set_home
    if params[:user][:home_lat] and params[:user][:home_lon]
      @user.home_lat = params[:user][:home_lat].to_f
      @user.home_lon = params[:user][:home_lon].to_f
      if @user.save
        flash[:notice] = "Home location saved successfully."
        redirect_to :controller => 'user', :action => 'account'
      end
    end
  end

  def go_public
    @user.data_public = true
    @user.save
    flash[:notice] = 'All your edits are now public.'
    redirect_to :controller => 'user', :action => 'account', :display_name => @user.display_name
  end

  def lost_password
    @title = 'lost password'
    if params[:user] and params[:user][:email]
      user = User.find_by_email(params[:user][:email])
      if user
        token = user.tokens.create
        Notifier::deliver_lost_password(user, token)
        flash[:notice] = "Sorry you lost it :-( but an email is on its way so you can reset it soon."
      else
        flash[:notice] = "Couldn't find that email address, sorry."
      end
    else
      render :action => 'lost_password'
    end
  end

  def reset_password
    @title = 'reset password'
    if params['token']
      token = UserToken.find_by_token(params[:token])
      if token
        pass = OSM::make_token(8)
        user = token.user
        user.pass_crypt = pass
        user.pass_crypt_confirmation = pass
        user.active = true
        user.save!
        token.destroy
        Notifier::deliver_reset_password(user, pass)
        flash[:notice] = "Your password has been changed and is on its way to your mailbox :-)"
      else
        flash[:notice] = "Didn't find that token, check the URL maybe?"
      end
    end
    redirect_to :action => 'login'
  end

  def new
    @title = 'create account'
  end

  def login
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
      elsif User.authenticate(:username => email_or_display_name, :password => pass, :invalid => true)
        flash[:notice] = "Sorry, your account is not active yet.<br>Please click on the link in the account confirmation email to activate your account."
      else
        flash[:notice] = "Sorry, couldn't log in with those details."
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
    token = UserToken.find_by_token(params[:confirm_string])
    if token and !token.user.active?
      @user = token.user
      @user.active = true
      @user.save!
      token.destroy
      flash[:notice] = 'Confirmed your account, thanks for signing up!'
      session[:user] = @user.id
      redirect_to :action => 'account', :display_name => @user.display_name
    else
      flash[:notice] = 'Something went wrong confirming that user.'
    end
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
    @this_user = User.find_by_display_name(params[:display_name])

    if @this_user
      @title = @this_user.display_name
    else
      render :nothing => true, :status => :not_found
    end
  end

  def make_friend
    if params[:display_name]     
      name = params[:display_name]
      new_friend = User.find_by_display_name(name)
      friend = Friend.new
      friend.user_id = @user.id
      friend.friend_user_id = new_friend.id
      unless @user.is_friends_with?(new_friend)
        if friend.save
          flash[:notice] = "#{name} is now your friend."
          Notifier::deliver_friend_notification(friend)
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
      friend = User.find_by_display_name(name)
      if @user.is_friends_with?(friend)
        Friend.delete_all "user_id = #{@user.id} AND friend_user_id = #{friend.id}"
        flash[:notice] = "#{friend.display_name} was removed from your friends."
      else
        flash[:notice] = "#{friend.display_name} was not already one of your friends."
      end
      redirect_to :controller => 'user', :action => 'view'
    end
  end

end

