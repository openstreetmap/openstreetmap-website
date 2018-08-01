class ErrorsController < ApplicationController
  layout "error"

  def forbidden
    render :status => :forbidden
  end

  def not_found
    render :status => :not_found
  end

  def internal_server_error
    render :status => :internal_server_error
  end
end
