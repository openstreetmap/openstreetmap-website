class UserController < ApplicationController
  layout 'site'

  before_filter :authorize, :only => [:preferences, :api_details, :api_gpx_files]
  before_filter :authorize_web, :only => [:edit, :account, :go_public, :view, :diary]
  before_filter :require_user, :only => [:edit, :account, :go_public]
 
  def save
    @user = User.new(params[:user])
    @user.set_defaults

    if @user.save
      flash[:notice] = 'User was successfully created. Check your email for a confirmation note, and you\'ll be mapping in no time :-)'
      Notifier::deliver_signup_confirm(@user)
      redirect_to :action => 'login'
    else
      render :action => 'new'
    end
  end

  def edit
    if params[:user] and params[:user][:display_name] and params[:user][:description]
      @user.display_name = params[:user][:display_name]
      @user.description = params[:user][:description]
      if @user.save
        flash[:notice] = "User edited OK."
        redirect_to :controller => 'user', :action => 'account'
      end
    end
  end

  def go_public
    @user.data_public = true
    @user.save
    flash[:notice] = 'All your edits are now public'
    redirect_to :controller => 'user', :action => 'account'
  end

  def lost_password
    if params['user']['email']
      user = User.find_by_email(params['user']['email'])
      if user
        user.token = User.make_token
        user.save
        Notifier::deliver_lost_password(user)
        flash[:notice] = "Sorry you lost it :-( but an email is on it's way so you can reset it soon."
      else
        flash[:notice] = "Couldn't find that email address, sorry."
      end
    end
  end

  def reset_password
    if params['token']
      user = User.find_by_token(params['token'])
      if user
        pass = User.make_token(8)
        user.pass_crypt = pass
        user.save
        Notifier::deliver_reset_password(user, pass)
        flash[:notice] = "You're password has been changed and is on the way to your mailbox :-)"
      else
        flash[:notice] = "Didn't find that token, check the URL maybe?"
      end
    end
    redirect_to :action => 'login'
  end

  def new
  end

  def login
    if params[:user]
      email = params[:user][:email]
      pass = params[:user][:password]
      u = User.authenticate(email, pass)
      if u
        u.token = User.make_token
        u.timeout = 1.day.from_now
        u.save
        session[:token] = u.token
        redirect_to :controller => 'site', :action => 'index'
        return
      else
        flash[:notice] = "Couldn't log in with those details"
      end
    end
  end

  def logout
    if session[:token]
      u = User.find_by_token(session[:token])
      if u
        u.token = User.make_token
        u.timeout = Time.now
        u.save
      end
    end
    session[:token] = nil
    redirect_to :controller => 'site', :action => 'index'
  end

  def confirm
    @user = User.find_by_token(params[:confirm_string])
    if @user && @user.active == 0
      @user.active = true
      @user.save
      flash[:notice] = 'Confirmed your account, thanks for signing up!'

      #FIXME: login the person magically

      redirect_to :action => 'login'
    else
      flash[:notice] = 'Something went wrong confirming that user'
    end
  end

  def preferences
    if request.get?
      render_text @user.preferences
    elsif request.post? or request.put?
      @user.preferences = request.raw_post
      @user.save!
      render :nothing => true
    else
      render :status => 400, :nothing => true
    end
  end

  def api_details
    render :text => @user.to_xml.to_s
  end

  def api_gpx_files
    doc = OSM::API.new.get_xml_doc
    @user.traces.each do |trace|
      doc.root << trace.to_xml_node() if trace.public? or trace.user == @user
    end
    render :text => doc.to_s
  end

  def view
    @this_user = User.find_by_display_name(params[:display_name])
  end

  def diary
    @this_user = User.find_by_display_name(params[:display_name])
  end


end

