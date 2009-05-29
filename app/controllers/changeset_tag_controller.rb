class ChangesetTagController < ApplicationController
  layout 'site'

  before_filter :set_locale

  def search
    @tags = ChangesetTag.find(:all, :limit => 11, :conditions => ["match(v) against (?)", params[:query][:query].to_s] )
  end


end
