class UserBlocksController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:new, :create, :edit, :update, :revoke]
  before_filter :require_moderator, :only => [:new, :create, :edit, :update, :revoke]
  before_filter :lookup_this_user, :only => [:new, :create, :blocks_on, :blocks_by]
  before_filter :lookup_user_block, :only => [:show, :edit, :update, :revoke]
  before_filter :require_valid_params, :only => [:create, :update]
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:create, :update, :revoke]

  def index
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :creator, :revoker],
                                                :order => "user_blocks.ends_at DESC",
                                                :per_page => 20)
  end

  def show
    if @user and @user.id == @user_block.user_id
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
        :user_id => @this_user.id,
        :creator_id => @user.id,
        :reason => params[:user_block][:reason],
        :ends_at => Time.now.getutc() + @block_period.hours,
        :needs_view => params[:user_block][:needs_view]
      )

      if @user_block.save
        flash[:notice] = t('user_block.create.flash', :name => @this_user.display_name)
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
      if @user_block.creator_id != @user.id
        flash[:error] = t('user_block.update.only_creator_can_edit')
        redirect_to :action => "edit"
      elsif @user_block.update_attributes(
              :ends_at => Time.now.getutc() + @block_period.hours,
              :reason => params[:user_block][:reason],
              :needs_view => params[:user_block][:needs_view]
            )
        flash[:notice] = t('user_block.update.success')
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
      if @user_block.revoke! @user
        flash[:notice] = t'user_block.revoke.flash'
        redirect_to(@user_block)
      end
    end
  end

  ##
  # shows a list of all the blocks on the given user
  def blocks_on
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :creator, :revoker],
                                                :conditions => {:user_id => @this_user.id},
                                                :order => "user_blocks.ends_at DESC",
                                                :per_page => 20)
  end

  ##
  # shows a list of all the blocks by the given user.
  def blocks_by
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :creator, :revoker],
                                                :conditions => {:creator_id => @this_user.id},
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
      flash[:error] = t('user_block.filter.block_period')

    elsif @user_block and !@user_block.active?
      flash[:error] = t('user_block.filter.block_expired')

    else
      @valid_params = true
    end
  end

end
