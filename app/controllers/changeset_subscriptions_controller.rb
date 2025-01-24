class ChangesetSubscriptionsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_writable

  authorize_resource :class => :changeset_subscription

  around_action :web_timeout

  def show
    @changeset = Changeset.find(params[:changeset_id])
    @subscribed = @changeset.subscribed?(current_user)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def create
    @changeset = Changeset.find(params[:changeset_id])

    @changeset.subscribe(current_user) unless @changeset.subscribed?(current_user)

    redirect_to changeset_path(@changeset)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  def destroy
    @changeset = Changeset.find(params[:changeset_id])

    @changeset.unsubscribe(current_user)

    redirect_to changeset_path(@changeset)
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end
end
