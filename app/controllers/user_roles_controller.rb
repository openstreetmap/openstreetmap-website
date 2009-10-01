class UserRolesController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :require_user
  before_filter :lookup_this_user
  before_filter :require_administrator
  before_filter :require_valid_role
  before_filter :not_in_role, :only => [:grant]
  before_filter :in_role, :only => [:revoke]
  around_filter :setup_nonce

  def grant
    @this_user.roles.create(:role => @role, :granter_id => @user.id)
    redirect_to :controller => 'user', :action => 'view', :display_name => @this_user.display_name
  end

  def revoke
    UserRole.delete_all({:user_id => @this_user.id, :role => @role})
    redirect_to :controller => 'user', :action => 'view', :display_name => @this_user.display_name
  end

  private
  def require_administrator
    unless @user.administrator?
      flash[:notice] = t'user_role.filter.not_an_administrator'
      redirect_to :controller => 'user', :action => 'view', :display_name => @this_user.display_name
    end
  end

  ##
  # ensure that there is a "this_user" instance variable
  def lookup_this_user
    @this_user = User.find_by_display_name(params[:display_name])
  rescue ActiveRecord::RecordNotFound
    redirect_to :controller => 'user', :action => 'view', :display_name => params[:display_name] unless @this_user
  end

  ##
  # the random nonce here which isn't predictable, making an CSRF 
  # procedure much, much more difficult. setup the nonce. if the given
  # nonce matches the session nonce then yield into the actual method.
  # otherwise, just sets up the nonce for the form.
  def setup_nonce
    if params[:nonce] and params[:nonce] == session[:nonce]
      @nonce = params[:nonce]
      yield
    else
      @nonce = OAuth::Helper.generate_nonce
      session[:nonce] = @nonce
      render
    end
  end    

  ##
  # require that the given role is valid. the role is a URL 
  # parameter, so should always be present.
  def require_valid_role
    @role = params[:role]
    unless UserRole::ALL_ROLES.include?(@role)
      flash[:notice] = t('user_role.filter.not_a_role', :role => @role)
      redirect_to :controller => 'user', :action => 'view', :display_name => @this_user.display_name
    end
  end

  ##
  # checks that the user doesn't already have this role
  def not_in_role
    if @this_user.has_role? @role
      flash[:notice] = t('user_role.filter.already_has_role', :role => @role)
      redirect_to :controller => 'user', :action => 'view', :display_name => @this_user.display_name
    end
  end

  ##
  # checks that the user already has this role
  def in_role
    unless @this_user.has_role? @role
      flash[:notice] = t('user_role.filter.doesnt_have_role', :role => @role)
      redirect_to :controller => 'user', :action => 'view', :display_name => @this_user.display_name
    end
  end
end
