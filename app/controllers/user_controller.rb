class UserController < ApplicationController

  def create
    # do some checks, find the user then send the mail
    Notifier::deliver_confirm_signup(user)
  end
  
  def new

  end
end
