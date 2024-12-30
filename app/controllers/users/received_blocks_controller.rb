module Users
  class ReceivedBlocksController < ApplicationController
    include UserMethods
    include PaginationMethods

    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => UserBlock

    before_action :lookup_user
    before_action :check_database_readable
    before_action :check_database_writable, :only => :destroy

    ##
    # shows a list of all the blocks on the given user
    def show
      @params = params.permit(:user_display_name)

      user_blocks = UserBlock.where(:user => @user)

      @user_blocks, @newer_user_blocks_id, @older_user_blocks_id = get_page_items(user_blocks, :includes => [:user, :creator, :revoker])

      @show_user_name = false
      @show_creator_name = true

      render :partial => "user_blocks/page" if turbo_frame_request_id == "pagination"
    end

    ##
    # shows revoke all active blocks page
    def edit; end

    ##
    # revokes all active blocks
    def destroy
      if params[:confirm]
        @user.blocks.active.each { |block| block.revoke!(current_user) }
        flash[:notice] = t ".flash"
        redirect_to user_received_blocks_path(@user)
      else
        render :action => :edit
      end
    end
  end
end
