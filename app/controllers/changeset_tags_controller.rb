class ChangesetTagsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  def index
    Changeset.find(params[:changeset_id])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
