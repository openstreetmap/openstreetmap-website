class UserController < ApplicationController

  def save
    @user = User.new(params[:user])
#    @user.save
    #Notifier::deliver_confirm_signup(user)
  end
  
  def new

  end
end
