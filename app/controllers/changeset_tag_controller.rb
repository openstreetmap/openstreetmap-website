class ChangesetTagController < ApplicationController
  layout 'site'

  def search
    @tags = ChangesetTag.find(:all, :limit => 11, :conditions => ["match(v) against (?)", params[:query][:query].to_s] )
  end

end
