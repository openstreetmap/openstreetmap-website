class OauthClientsController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user

  def index
    @client_applications = @user.client_applications
    @tokens = @user.oauth_tokens.authorized
  end

  def new
    @client_application = ClientApplication.new
  end

  def create
    @client_application = @user.client_applications.build(application_params)
    if @client_application.save
      flash[:notice] = t 'oauth_clients.create.flash'
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "new"
    end
  end

  def show
    @client_application = @user.client_applications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @type = "client application"
    render :action => "not_found", :status => :not_found
  end

  def edit
    @client_application = @user.client_applications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @type = "client application"
    render :action => "not_found", :status => :not_found
  end

  def update
    @client_application = @user.client_applications.find(params[:id])
    if @client_application.update_attributes(application_params)
      flash[:notice] = t 'oauth_clients.update.flash'
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "edit"
    end
  rescue ActiveRecord::RecordNotFound
    @type = "client application"
    render :action => "not_found", :status => :not_found
  end

  def destroy
    @client_application = @user.client_applications.find(params[:id])
    @client_application.destroy
    flash[:notice] = t 'oauth_clients.destroy.flash'
    redirect_to :action => "index"
  rescue ActiveRecord::RecordNotFound
    @type = "client application"
    render :action => "not_found", :status => :not_found
  end

  private

  def application_params
    params.require(:client_application).permit(:name, :url, :callback_url, :support_url, ClientApplication.all_permissions)
  end
end
