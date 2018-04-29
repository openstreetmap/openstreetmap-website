class UserRolesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :require_user
  before_action :lookup_user
  before_action :require_administrator
  before_action :require_valid_role
  before_action :not_in_role, :only => [:grant]
  before_action :in_role, :only => [:revoke]

  def grant
    @user.roles.create(:role => @role, :granter => current_user)
    redirect_to user_path(@user)
  end

  def revoke
    # checks that administrator role is not revoked from current user
    if current_user == @user && @role == "administrator"
      flash[:error] = t("user_role.filter.not_revoke_admin_current_user")
    else
      UserRole.where(:user_id => @user.id, :role => @role).delete_all
    end
    redirect_to user_path(@user)
  end

  private

  ##
  # require that the user is an administrator, or fill out a helpful error message
  # and return them to theuser page.
  def require_administrator
    unless current_user.administrator?
      flash[:error] = t "user_role.filter.not_an_administrator"
      redirect_to user_path(@user)
    end
  end

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
    if @user.has_role? @role
      flash[:error] = t("user_role.filter.already_has_role", :role => @role)
      redirect_to user_path(@user)
    end
  end

  ##
  # checks that the user already has this role
  def in_role
    unless @user.has_role? @role
      flash[:error] = t("user_role.filter.doesnt_have_role", :role => @role)
      redirect_to user_path(@user)
    end
  end
end
