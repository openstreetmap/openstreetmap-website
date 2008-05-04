# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_write_availability, :only => [:create, :update, :delete]
  before_filter :check_read_availability, :except => [:create, :update, :delete]

  # Create a changeset from XML.
  def create
    if request.put?
      cs = Changeset.from_xml(request.raw_post, true)

      if cs
        cs.user_id = @user.id
        cs.save_with_tags!
        render :text => cs.id.to_s, :content_type => "text/plain"
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :method_not_allowed
    end
  end
end
