class UserRolesController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web

  authorize_resource

  before_action :lookup_user
  before_action :require_valid_role
  before_action :not_in_role, :only => :create
  before_action :in_role, :only => :destroy

  def create
    @user.roles.create(:role => @role, :granter => current_user)
    redirect_to user_path(@user)
  end

  def destroy
    # checks that administrator role is not revoked from current user
    if current_user == @user && @role == "administrator"
      flash[:error] = t("user_role.filter.not_revoke_admin_current_user")
    else
      UserRole.where(:user => @user, :role => @role).delete_all
    end
    redirect_to user_path(@user)
  end

  private

  ##
  # require that the given role is valid. the role is a URL
  # parameter, so should always be present.
  def require_valid_role
    @role = params[:role]
    unless UserRole::ALL_ROLES.include?(@role)
      flash[:error] = t("user_role.filter.not_a_role", :role => @role)
      redirect_to user_path(@user)
    end
  end

  ##
  # checks that the user doesn't already have this role
  def not_in_role
    if @user.role? @role
      flash[:error] = t("user_role.filter.already_has_role", :role => @role)
      redirect_to user_path(@user)
    end
  end

  ##
  # checks that the user already has this role
  def in_role
    unless @user.role? @role
      flash[:error] = t("user_role.filter.doesnt_have_role", :role => @role)
      redirect_to user_path(@user)
    end
  end
end
