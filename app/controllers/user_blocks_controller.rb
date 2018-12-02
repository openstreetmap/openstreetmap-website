class UserBlocksController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:new, :create, :blocks_on, :blocks_by]
  before_action :lookup_user_block, :only => [:show, :edit, :update, :revoke]
  before_action :require_valid_params, :only => [:create, :update]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:create, :update, :revoke]

  def index
    @params = params.permit
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :creator, :revoker],
                                                :order => "user_blocks.ends_at DESC",
                                                :per_page => 20)
  end

  def show
    if current_user && current_user == @user_block.user
      @user_block.needs_view = false
      @user_block.save!
    end
  end

  def new
    @user_block = UserBlock.new
  end

  def edit
    params[:user_block_period] = ((@user_block.ends_at - Time.now.getutc) / 1.hour).ceil.to_s
  end

  def create
    if @valid_params
      @user_block = UserBlock.new(
        :user => @user,
        :creator => current_user,
        :reason => params[:user_block][:reason],
        :ends_at => Time.now.getutc + @block_period.hours,
        :needs_view => params[:user_block][:needs_view]
      )

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
      if @user_block.creator != current_user
        flash[:error] = t(".only_creator_can_edit")
        redirect_to :action => "edit"
      elsif @user_block.update(
        :ends_at => Time.now.getutc + @block_period.hours,
        :reason => params[:user_block][:reason],
        :needs_view => params[:user_block][:needs_view]
      )
        flash[:notice] = t(".success")
        redirect_to(@user_block)
      else
        render :action => "edit"
      end
    else
      redirect_to edit_user_block_path(:id => params[:id])
    end
  end

  ##
  # revokes the block, setting the end_time to now
  def revoke
    if params[:confirm]
      if @user_block.revoke! current_user
        flash[:notice] = t ".flash"
        redirect_to(@user_block)
      end
    end
  end

  ##
  # shows a list of all the blocks on the given user
  def blocks_on
    @params = params.permit(:display_name)
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :creator, :revoker],
                                                :conditions => { :user_id => @user.id },
                                                :order => "user_blocks.ends_at DESC",
                                                :per_page => 20)
  end

  ##
  # shows a list of all the blocks by the given user.
  def blocks_by
    @params = params.permit(:display_name)
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :creator, :revoker],
                                                :conditions => { :creator_id => @user.id },
                                                :order => "user_blocks.ends_at DESC",
                                                :per_page => 20)
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

    if !UserBlock::PERIODS.include?(@block_period)
      flash[:error] = t("user_blocks.filter.block_period")

    elsif @user_block && !@user_block.active?
      flash[:error] = t("user_blocks.filter.block_expired")

    else
      @valid_params = true
    end
  end
end
