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

  end

  def confirm
    @user = User.find_by_token(params[:confirm_string])
    if @user && @user.active == 0
      @user.active = true
      @user.save
      flash[:notice] = 'Confirmed your account'
      redirect_to :action => 'login'
    else
      flash[:notice] = 'Something went wrong confirming that user'
    end
  end

end
