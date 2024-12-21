module Api
  module Users
    class DetailsController < ApiController
      before_action :disable_terms_redirect
      before_action :authorize

      authorize_resource :class => :user_details

      before_action :set_request_formats

      def show
        @user = current_user
        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      end

      private

      def disable_terms_redirect
        # this is necessary otherwise going to the user terms page, when
        # having not agreed already would cause an infinite redirect loop.
        # it's .now so that this doesn't propagate to other pages.
        flash.now[:skip_terms] = true
      end
    end
  end
end
