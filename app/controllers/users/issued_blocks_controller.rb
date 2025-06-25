module Users
  class IssuedBlocksController < ApplicationController
    include UserMethods
    include PaginationMethods

    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => UserBlock

    before_action :lookup_user
    before_action :check_database_readable

    ##
    # shows a list of all the blocks by the given user.
    def show
      @params = params.permit(:user_display_name)

      user_blocks = UserBlock.where(:creator => @user)

      @user_blocks, @newer_user_blocks_id, @older_user_blocks_id = get_page_items(user_blocks, :includes => [:user, :creator, :revoker])

      @show_user_name = true
      @show_creator_name = false

      render :partial => "user_blocks/page" if turbo_frame_request_id == "pagination"
    end
  end
end
