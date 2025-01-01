module Api
  module UserBlocks
    class ActiveListsController < ApiController
      before_action :authorize

      authorize_resource :class => :active_user_blocks_list

      before_action :set_request_formats

      def show; end
    end
  end
end
