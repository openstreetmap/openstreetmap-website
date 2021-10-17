class Oauth2ApplicationsController < Doorkeeper::ApplicationsController
  layout "site"

  prepend_before_action :authorize_web
  before_action :set_locale
  before_action :set_application, :only => [:show, :edit, :update, :destroy]

  authorize_resource :class => false

  def index
    @applications = current_resource_owner.oauth2_applications.ordered_by(:created_at)
  end

  private

  def set_application
    @application = current_resource_owner&.oauth2_applications&.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def application_params
    params[:oauth2_application][:scopes]&.delete("")
    params.require(:oauth2_application)
          .permit(:name, :redirect_uri, :confidential, :scopes => [])
          .merge(:owner => current_resource_owner)
  end
end
