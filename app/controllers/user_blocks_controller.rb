class UserBlocksController < ApplicationController
  include UserMethods
  include PaginationMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:new, :create, :revoke_all, :blocks_on, :blocks_by]
  before_action :lookup_user_block, :only => [:show, :edit, :update]
  before_action :require_valid_params, :only => [:create, :update]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:create, :update, :revoke_all]

  def index
    @params = params.permit

    user_blocks = UserBlock.all

    @user_blocks, @newer_user_blocks_id, @older_user_blocks_id = get_page_items(user_blocks, :includes => [:user, :creator, :revoker])

    @show_user_name = true
    @show_creator_name = true

    render :partial => "page" if turbo_frame_request_id == "pagination"
  end

  def show
    if current_user && current_user == @user_block.user && !@user_block.deactivates_at
      @user_block.needs_view = false
      @user_block.deactivates_at = [@user_block.ends_at, Time.now.utc].max
      @user_block.save!
    end
  end

  def new
    @user_block = UserBlock.new
  end

  def edit
    params[:user_block_period] = ((@user_block.ends_at - Time.now.utc) / 1.hour).ceil.to_s
  end

  def create
    if @valid_params
      now = Time.now.utc
      @user_block = UserBlock.new(
        :user => @user,
        :creator => current_user,
        :reason => params[:user_block][:reason],
        :created_at => now,
        :ends_at => now + @block_period.hours,
        :needs_view => params[:user_block][:needs_view]
      )
      @user_block.deactivates_at = @user_block.ends_at unless @user_block.needs_view

      if @user_block.save
        flash[:notice] = t(".flash", :name => @user.display_name)
        redirect_to @user_block
      else
        render :action => "new"
      end
    else
      redirect_to new_user_block_path(:display_name => params[:display_name])
    end
  end

  def update
    if @valid_params
      if cannot?(:update, @user_block)
        flash[:error] = @user_block.revoker ? t(".only_creator_or_revoker_can_edit") : t(".only_creator_can_edit")
        redirect_to :action => "edit"
      else
        user_block_was_active = @user_block.active?
        @user_block.reason = params[:user_block][:reason]
        @user_block.needs_view = params[:user_block][:needs_view]
        @user_block.ends_at = Time.now.utc + @block_period.hours
        @user_block.deactivates_at = (@user_block.ends_at unless @user_block.needs_view)
        @user_block.revoker = current_user if user_block_was_active && !@user_block.active?
        if user_block_was_active && @user_block.active? && current_user != @user_block.creator
          flash.now[:error] = t(".only_creator_can_edit_without_revoking")
          render :action => "edit"
        elsif !user_block_was_active && @user_block.active?
          flash.now[:error] = t(".inactive_block_cannot_be_reactivated")
          render :action => "edit"
        else
          unless user_block_was_active
            @user_block.ends_at = @user_block.ends_at_was
            @user_block.deactivates_at = @user_block.deactivates_at_was
            @user_block.deactivates_at = [@user_block.ends_at, @user_block.updated_at].max unless @user_block.deactivates_at # take updated_at into account before deactivates_at is backfilled
          end
          if @user_block.save
            flash[:notice] = t(".success")
            redirect_to @user_block
          else
            render :action => "edit"
          end
        end
      end
    else
      redirect_to edit_user_block_path(:id => params[:id])
    end
  end

  ##
  # revokes all active blocks
  def revoke_all
    if request.post? && params[:confirm]
      @user.blocks.active.each { |block| block.revoke!(current_user) }
      flash[:notice] = t ".flash"
      redirect_to user_blocks_on_path(@user)
    end
  end

  ##
  # shows a list of all the blocks on the given user
  def blocks_on
    @params = params.permit(:display_name)

    user_blocks = UserBlock.where(:user => @user)

    @user_blocks, @newer_user_blocks_id, @older_user_blocks_id = get_page_items(user_blocks, :includes => [:user, :creator, :revoker])

    @show_user_name = false
    @show_creator_name = true

    render :partial => "page" if turbo_frame_request_id == "pagination"
  end

  ##
  # shows a list of all the blocks by the given user.
  def blocks_by
    @params = params.permit(:display_name)

    user_blocks = UserBlock.where(:creator => @user)

    @user_blocks, @newer_user_blocks_id, @older_user_blocks_id = get_page_items(user_blocks, :includes => [:user, :creator, :revoker])

    @show_user_name = true
    @show_creator_name = false

    render :partial => "page" if turbo_frame_request_id == "pagination"
  end

  private

  ##
  # ensure that there is a "user_block" instance variable
  def lookup_user_block
    @user_block = UserBlock.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  ##
  # check that the input parameters are valid, setting an instance
  # variable if not. note that this doesn't do any redirection, as it's
  # called before two different actions, each of which should redirect
  # to a different place.
  def require_valid_params
    @block_period = params[:user_block_period].to_i
    @valid_params = false

    if UserBlock::PERIODS.exclude?(@block_period)
      flash[:error] = t("user_blocks.filter.block_period")

    else
      @valid_params = true
    end
  end
end
