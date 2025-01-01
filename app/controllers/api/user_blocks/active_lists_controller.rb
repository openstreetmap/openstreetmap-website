module Api
  module UserBlocks
    class ActiveListsController < ApiController
      before_action :disable_blocks_check
      before_action :authorize

      authorize_resource :class => :active_user_blocks_list

      before_action :set_request_formats

      def show; end

      private

      def disable_blocks_check
        flash.now[:skip_blocks] = true
      end
    end
  end
end
