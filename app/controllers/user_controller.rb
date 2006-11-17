class UserController < ApplicationController
  layout 'site'
  
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

end
