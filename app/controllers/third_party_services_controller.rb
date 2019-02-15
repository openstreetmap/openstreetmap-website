class ThirdPartyServicesController < ApplicationController
  skip_authorization_check

  require "xml/libxml"

  layout "site"

  before_action :authorize, :only => [:index, :create, :edit, :show, :update, :destroy]
  before_action :authorize_web, :only => [:index, :create, :edit, :show, :update, :destroy]
  before_action :set_locale, :only => [:index, :create, :edit, :update, :destroy]
  before_action :require_user, :only => [:index, :create, :edit, :update, :destroy]
  around_action :api_call_handle_error, :api_call_timeout

  def index
    @services = ThirdPartyService.all.where(:user_ref => current_user.id)
  end

  def create
    @service = ThirdPartyService.new(application_params)
    @service.user_ref = current_user.id
    @service.access_key = SecureRandom.hex(20)
    if @service.save
      redirect_to :action => "show", :id => @service.id
    else
      render :action => "new"
    end
  end

  def edit
    @service = ThirdPartyService.find(params[:id])
    render :action => "show" if !(@service && @service.user_ref == current_user.id)
  end

  def show
    @service = ThirdPartyService.find(params[:id])
    @service_owner = User.find(@service.user_ref)
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => "index"
  end

  def update
    @service = ThirdPartyService.find(params[:id])
    if @service.user_ref != current_user.id
      redirect_to @service
    else
      @service.access_key = SecureRandom.hex(20)
      if @service.save
        redirect_to @service
      else
        redirect_to :action => "edit"
      end
    end
  end

  def destroy
    @service = ThirdPartyService.find(params[:id])
    if @service.user_ref != current_user.id
      redirect_to @service
    else
      @service.access_key = ""
      if @service.save
        redirect_to @service
      else
        redirect_to :action => "edit"
      end
    end
  end

  def retrieve_keys
    raise OSM::APIBadUserInput, "The parameters service, key, and beyond are required" unless params["service"] && params["key"] && params["beyond"]

    service = ThirdPartyService.find_by :uri => params["service"]
    raise OSM::APIBadUserInput, "Service not found" unless service
    raise OSM::APIPreconditionFailedError, "Access key does not match" unless service.access_key == params["key"]

    beyond = params[:beyond]

    doc = OSM::API.new.get_xml_credentials_doc

    ThirdPartyKey.where("third_party_service_id = ? and revoked_ref > ? and created_ref <= ?", service.id, beyond, beyond).each do |key|
      doc.root << key.to_xml_for_retrieve
    end
    ThirdPartyKey.where("third_party_service_id = ? and created_ref > ? and (revoked_ref is null or revoked_ref = 0)", service.id, beyond).each do |key|
      doc.root << key.to_xml_for_retrieve
    end

    latest_event = ThirdPartyKeyEvent.last

    el = XML::Node.new "keyid"
    el["max"] = latest_event ? latest_event.id.to_s : "0"
    doc.root << el

    render :xml => doc.to_s
  end

  private

  def application_params
    params.require(:third_party_service).permit(:uri)
  end
end
