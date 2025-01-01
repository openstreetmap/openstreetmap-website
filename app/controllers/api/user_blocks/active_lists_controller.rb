module Api
  module UserBlocks
    class ActiveListsController < ApiController
      before_action -> { authorize(:skip_blocks => true) }

      authorize_resource :class => :active_user_blocks_list

      before_action :set_request_formats

      def show
        @user_blocks = current_user.blocks.active.order(:id => :desc)
        @skip_reason = true
      end
    end
  end
end
