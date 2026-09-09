# frozen_string_literal: true

class AclsController < ApplicationController
  layout :site_layout

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :check_database_readable
  before_action :check_database_writable, :except => [:index]
  before_action :set_acl, :only => [:edit, :update, :destroy]

  def index
    @acls = Acl.order(:id)
  end

  def new
    @acl = Acl.new
  end

  def edit; end

  def create
    @acl = Acl.new(acl_params)

    if @acl.save
      redirect_to acls_path, :notice => t(".success")
    else
      render :new, :status => :unprocessable_content
    end
  end

  def update
    if @acl.update(acl_params)
      redirect_to acls_path, :notice => t(".success"), :status => :see_other
    else
      render :edit, :status => :unprocessable_content
    end
  end

  def destroy
    @acl.destroy
    redirect_to acls_path, :notice => t(".success"), :status => :see_other
  end

  private

  def set_acl
    @acl = Acl.find(params.expect(:id))
  end

  def acl_params
    params.expect(:acl => [:address, :domain, :mx, :k, :v])
  end
end
