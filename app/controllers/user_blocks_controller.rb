class UserBlocksController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:new, :create, :edit, :delete]
  before_filter :require_moderator, :only => [:new, :create, :edit, :delete]

  def index
    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                            :include => [:user, :moderator, :revoker],
                                            :order => "user_blocks.end_at DESC",
                                            :per_page => 20)
  end

  def show
    @user_block = UserBlock.find(params[:id])

    if @user and @user.id == @user_block.user_id
      @user_block.needs_view = false
      @user_block.save!
    end
  end

  def new
    @user_block = UserBlock.new
    @display_name = params[:display_name]
    @this_user = User.find_by_display_name(@display_name, :conditions => {:visible => true})
  end

  # GET /user_blocks/1/edit
  def edit
    @user_block = UserBlock.find(params[:id])
    params[:user_block_period] = ((@user_block.end_at - Time.now.getutc) / 1.hour).ceil.to_s
  end

  def create
    @display_name = params[:display_name]
    @this_user = User.find_by_display_name(@display_name, :conditions => {:visible => true})
    block_period = [UserBlock::PERIODS.max, params[:user_block_period].to_i].min

    @user_block = UserBlock.new(:user_id => @this_user.id,
                                :moderator_id => @user.id,
                                :reason => params[:user_block][:reason],
                                :end_at => Time.now.getutc() + block_period.hours,
                                :needs_view => params[:user_block][:needs_view])
    
    if (@this_user and @user.moderator? and 
        params[:tried_contacting] == "yes" and
        params[:tried_waiting] == "yes" and
        block_period >= 0)
      if @user_block.save
        flash[:notice] = t('user_block.create.flash', :name => @display_name)
        redirect_to @user_block
      else
        render :action => "new"
      end
    else
      if !@user.moderator?
        flash[:notice] = t('user_block.create.not_a_moderator')
      elsif params[:tried_contacting] != "yes"
        flash[:notice] = t('user_block.create.try_contacting')
      elsif params[:tried_waiting] != "yes"
        flash[:notice] = t('user_block.create.try_waiting')
      else
        flash[:notice] = t('user_block.create.bad_parameters')
      end
      @display_name = @this_user.nil? ? '' : @this_user.display_name

      render :action => "new"
    end
  end

  def update
    @user_block = UserBlock.find(params[:id])
    block_period = [72, params[:user_block_period].to_i].min
    
    if @user_block.moderator_id != @user.id
      flash[:notice] = t('user_block.update.only_creator_can_edit')
      redirect_to(@user_block)

    elsif !@user_block.active?
      flash[:notice] = t('user_block.update.block_expired')
      redirect_to(@user_block)
      
    elsif @user_block.update_attributes({ :end_at => Time.now.getutc() + block_period.hours,
                                          :reason => params[:user_block][:reason],
                                          :needs_view => params[:user_block][:needs_view] })
      flash[:notice] = t('user_block.update.success')
      redirect_to(@user_block)
    else
      render :action => "edit"
    end
  end

  ##
  # revokes the block, setting the end_time to now
  def revoke
    @user_block = UserBlock.find(params[:id])
    
    if !@user.moderator?
      flash[:notice] = t('user_block.create.not_a_moderator')
      redirect_to @user_block

    elsif params[:confirm]
      if @user_block.revoke!
        flash[:notice] = t'user_block.revoke.flash'
        redirect_to(@user_block)
      else
        flash[:notice] = t'user_block.revoke.error'
        render :action => "edit"
      end
    end
  end

  ##
  # shows a list of all the blocks on the given user
  def blocks_on
    @this_user = User.find_by_display_name(params[:display_name])

    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                                :include => [:user, :moderator, :revoker],
                                                :conditions => {:user_id => @this_user.id},
                                                :order => "user_blocks.end_at DESC",
                                                :per_page => 20)
  end

  ##
  # shows a list of all the blocks by the given user.
  def blocks_by
    @this_user = User.find_by_display_name(params[:display_name])

    @user_blocks_pages, @user_blocks = paginate(:user_blocks,
                                            :include => [:user, :moderator, :revoker],
                                            :conditions => {:moderator_id => @this_user.id},
                                            :order => "user_blocks.end_at DESC",
                                            :per_page => 20)
  end

  private
  def require_moderator
    redirect_to "/403.html" unless @user.moderator?
  end

end
