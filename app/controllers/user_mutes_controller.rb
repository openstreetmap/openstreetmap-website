class UserMutesController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:create, :destroy]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:create, :destroy]

  def index
    @muted_users = current_user.muted_users
    @title = t ".title"

    redirect_to account_path unless @muted_users.any?
  end

  def create
    user_mute = current_user.mutes.build(:subject => @user)

    if user_mute.save
      flash[:notice] = t(".notice", :name => user_mute.subject.display_name)
    else
      flash[:error] = t(".error", :name => user_mute.subject.display_name, :full_message => user_mute.errors.full_messages.to_sentence.humanize)
    end

    redirect_back_or_to user_mutes_path(current_user)
  end

  def destroy
    user_mute = current_user.mutes.find_by!(:subject => @user)

    if user_mute.destroy
      flash[:notice] = t(".notice", :name => user_mute.subject.display_name)
    else
      flash[:error] = t(".error")
    end

    redirect_back_or_to user_mutes_path(current_user)
  end
end
