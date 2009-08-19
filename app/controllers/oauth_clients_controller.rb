class OauthClientsController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user

  def index
    @client_applications = @user.client_applications
    @tokens = @user.oauth_tokens.find :all, :conditions => 'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'
  end

  def new
    @client_application = ClientApplication.new
  end

  def create
    @client_application = @user.client_applications.build(params[:client_application])
    if @client_application.save
      flash[:notice] = "Registered the information successfully"
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
  end

  def update
    @client_application = @user.client_applications.find(params[:id])
    if @client_application.update_attributes(params[:client_application])
      flash[:notice] = "Updated the client information successfully"
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "edit"
    end
  end

  def destroy
    @client_application = @user.client_applications.find(params[:id])
    @client_application.destroy
    flash[:notice] = "Destroyed the client application registration"
    redirect_to :action => "index"
  end
end
