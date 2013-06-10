class GroupsController < ApplicationController

  layout 'site'

  before_filter :check_api_readable
  before_filter :set_locale
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  ##
  # An index of Groups
  def index
    render :template => 'groups/index'
  end
end
