class UserController < ApplicationController

  def save
    @user = User.new(params[:user])
    @user.set_defaults

    if @user.save
      flash[:notice] = 'Users was successfully created.'
      Notifier::deliver_signup_confirm(@user)
      redirect_to :action => 'login'
    else
      render :action => 'new'
    end
  end

  def new
    render :layout => 'site'
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
      end
    end

    render :layout => 'site'
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
      flash[:notice] = 'Confirmed your account'

      #FIXME: login the person magically

      redirect_to :action => 'login'
    else
      flash[:notice] = 'Something went wrong confirming that user'
    end
  end

end
