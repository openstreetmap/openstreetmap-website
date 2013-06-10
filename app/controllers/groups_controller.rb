class GroupsController < ApplicationController

  layout 'site'

  before_filter :check_api_readable
  before_filter :set_locale
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  ##
  # An index of Groups
  def index
    @groups = Group.all()
    render :template => 'groups/index'
  end
  
  ##
  # create a new group
  #
  def new
    if params[:group]
      @group = Group.new()
      @group.title = params[:group][:title]
      @group.description=params[:group][:description]
      @group.save
    else
      @title = t 'group.new.group'
    end
  end
end
