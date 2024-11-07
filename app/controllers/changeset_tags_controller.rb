class ChangesetTagsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  def index
    @changeset = Changeset.find(params[:changeset_id])
  rescue ActiveRecord::RecordNotFound
    render :action => "changeset_not_found", :status => :not_found
  end

  def destroy
    begin
      @changeset = Changeset.find(params[:changeset_id])
    rescue ActiveRecord::RecordNotFound
      render :action => "changeset_not_found", :status => :not_found
      return
    end
    begin
      @changeset_tag = ChangesetTag.find([params[:changeset_id], params[:key]])
    rescue ActiveRecord::RecordNotFound
      render :action => "tag_not_found", :status => :not_found
      return
    end

    @changeset_tag.delete
    redirect_to changeset_tags_path(@changeset)
  end
end
