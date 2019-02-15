class ThirdPartyKeysController < ApplicationController
  skip_authorization_check

  layout "site"

  before_action :authorize
  before_action :authorize_web
  before_action :set_locale
  before_action :require_user

  def index
    @keys = ThirdPartyKey.all.where("user_ref = ? and (revoked_ref = 0 or revoked_ref is null)", current_user.id)
  end

  def create
    input = params.require(:third_party_key).permit(:gdpr, :attentive, :disclose, :service_to_use)
    service = ThirdPartyService.where(:uri => input[:service_to_use]).take
    unless service
      @error = "No service with this URI known."
      render :action => "new"
      return
    end
    if service.access_key == ""
      @error = "Service has been discontinued."
      render :action => "new"
      return
    end
    @key = ThirdPartyKey.where(:user_ref => current_user.id, :third_party_service => service).take
    if @key
      redirect_to :action => "show", :id => @key.id
      return
    end
    if input[:gdpr] != "1" || input[:attentive] == "1" || input[:disclose] == "1"
      @error = "Please read the text, check the appropriate checkboxes, and uncheck the others."
      render :action => "new"
      return
    end
    event = ThirdPartyKeyEvent.new
    event.save
    @key = ThirdPartyKey.new
    @key.created_ref = event.id
    @key.third_party_service = service
    @key.user_ref = current_user.id
    @key.data = SecureRandom.hex(20)
    if @key.save
      redirect_to :action => "show", :id => @key.id
    else
      render :action => "new"
    end
  end

  def edit
    @key = ThirdPartyKey.find(params[:id])
    if !@key
      redirect_to :action => "index"
    else
      render :action => "show" if @key.user_ref != current_user.id
    end
  end

  def show
    @key = ThirdPartyKey.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => "index"
  end

  def update
    @key = ThirdPartyKey.find(params[:id])
    if @key.user_ref != current_user.id
      redirect_to @key
    else
      event = ThirdPartyKeyEvent.new
      event.save
      @key.revoked_ref = event.id
      @key.save
      if @key.third_party_service && @key.third_party_service.access_key == ""
        redirect_to :action => "edit"
        return
      end
      service = @key.third_party_service

      event = ThirdPartyKeyEvent.new
      event.save
      @key = ThirdPartyKey.new
      @key.created_ref = event.id
      @key.third_party_service = service
      @key.user_ref = current_user.id
      @key.data = SecureRandom.hex(20)
      if @key.save
        redirect_to :action => "show", :id => @key.id
      else
        render :action => "edit"
      end
    end
  end

  def destroy
    @key = ThirdPartyKey.find(params[:id])
    if @key.user_ref != current_user.id
      redirect_to @key
    else
      event = ThirdPartyKeyEvent.new
      event.save
      @key.revoked_ref = event.id
      if @key.save
        redirect_to @key
      else
        redirect_to :action => "edit"
      end
    end
  end
end
