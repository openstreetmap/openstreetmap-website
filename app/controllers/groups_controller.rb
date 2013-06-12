class GroupsController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :check_api_readable
  before_filter :set_locale
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout
  before_filter :require_user , :except => [:index, :show]

  before_filter :find_group, :only => [:show, :edit, :update, :destroy, :leave, :join]

  ##
  # An index of Groups.
  def index
    @groups = Group.where('')
  end
  
  ##
  # The form for creating a new group.
  #
  def new
    @group = Group.new
  end

  ##
  # Process the POST'ing of the new group form.
  def create
    @group = Group.new(params[:group])
    if @group.save
      if defined?(@user)
        @group.users << @user
        # TODO: role
      end
      flash[:notice] = t 'group.create.success', :title => @group.title
      redirect_to group_url(@group)
    else
      render :action => "new"
    end
  end

  ##
  # Details page for one group.
  def show
  end

  ##
  # Form to edit an existing group,
  def edit
  end

  ##
  # Process the PUT'ing of an existing group.
  def update
    if @group.update_attributes(params[:group])
      flash[:notice] = t 'group.update.success', :title => @group.title
      redirect_to groups_url
    else
      render :action => "edit"
    end
  end

  ##
  # Delete an entire group.
  def destroy
    if @group.destroy
      flash[:notice] = t 'group.destroy.success', :title => @group.title
    else
      flash[:error] = t 'group.destroy.error', :title => @group.title
    end
    redirect_to groups_url
  end

  ##
  # Add a new member to a group.
  def join
    if @group.users << @user
      flash[:notice] = t 'group.join.success', :title => @group.title
    else
      flash[:error] = t 'group.join.error', :title => @group.title
    end
    redirect_to :back
  end

  ##
  # Remove a member from a group.
  def leave
    group_membership = @group.group_memberships.find_by_user_id(@user.id)
    if group_membership.blank?
      flash[:error] = t 'group.leave.not_in_group', :title => @group.title
    elsif group_membership.destroy
      flash[:notice] = t 'group.leave.success', :title => @group.title
    else
      flash[:error] = t 'group.leave.error', :title => @group.title
    end
    redirect_to :back
  end

private

  def find_group
    @group = Group.find(params[:id])
  end
end
