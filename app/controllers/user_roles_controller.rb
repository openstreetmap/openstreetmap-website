class UserRolesController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :require_user
  before_filter :require_administrator

  def grant
    # added a random nonce here which isn't predictable, making an CSRF procedure much, much more difficult.
    if params[:nonce] and params[:nonce] == session[:nonce]
      this_user = User.find_by_display_name(params[:display_name], :conditions => {:visible => true})
      if this_user and UserRole::ALL_ROLES.include? params[:role]
        this_user.roles.create(:role => params[:role], :granter_id => @user.id)
        redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
      else
        flash[:notice] = t('user_role.grant.fail', :role => params[:role], :name => params[:display_name])
      end
    else
      @nonce = OAuth::Helper.generate_nonce
      session[:nonce] = @nonce
    end
  end

  def revoke
    # added a random nonce here which isn't predictable, making an CSRF procedure much, much more difficult.
    if params[:nonce] and params[:nonce] == session[:nonce]
      this_user = User.find_by_display_name(params[:display_name], :conditions => {:visible => true})
      if this_user and UserRole::ALL_ROLES.include? params[:role]
        UserRole.delete_all({:user_id => this_user.id, :role => params[:role]})
        redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name]
      else
        flash[:notice] = t('user_role.revoke.fail', :role => params[:role], :name => params[:display_name])
      end
    else
      @nonce = OAuth::Helper.generate_nonce
      session[:nonce] = @nonce
    end
  end

  private
  def require_administrator
    redirect_to "/403.html" unless @user.administrator?
  end

end
