class ErrorsController < ApplicationController
  layout "error"

  skip_authorization_check

  before_action :set_locale

  def bad_request
    respond_to do |format|
      format.html { render :status => :bad_request }
      format.any { render :status => :bad_request, :plain => "" }
    end
  end

  def forbidden
    respond_to do |format|
      format.html { render :status => :forbidden }
      format.any { render :status => :forbidden, :plain => "" }
    end
  end

  def not_found
    respond_to do |format|
      format.html { render :status => :not_found }
      format.any { render :status => :not_found, :plain => "" }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render :status => :internal_server_error }
      format.any { render :status => :internal_server_error, :plain => "" }
    end
  end
end
