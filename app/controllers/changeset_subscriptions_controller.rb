class ChangesetSubscriptionsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_writable

  authorize_resource

  around_action :web_timeout

  def show
    @changeset = Changeset.find(params[:changeset_id])
    @subscribed = @changeset.subscribers.include?(current_user)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def create
    @changeset = Changeset.find(params[:changeset_id])

    @changeset.subscribers << current_user unless @changeset.subscribers.include?(current_user)

    redirect_to changeset_path(@changeset)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def destroy
    @changeset = Changeset.find(params[:changeset_id])

    @changeset.subscribers.delete(current_user)

    redirect_to changeset_path(@changeset)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end
end
