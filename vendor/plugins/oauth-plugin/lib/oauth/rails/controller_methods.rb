require 'oauth/signature'
module OAuth
  module Rails
   
    module ControllerMethods
      protected
      
      def current_token
        @current_token
      end
      
      def current_client_application
        @current_client_application
      end
      
      def oauthenticate
        logger.info "entering oauthenticate"
        verified=verify_oauth_signature 
        logger.info "verified=#{verified.to_s}"
        return verified && current_token.is_a?(::AccessToken)
      end
      
      def oauth?
        current_token!=nil
      end
      
      # use in a before_filter
      def oauth_required
        logger.info "Current_token=#{@current_token.inspect}"
        if oauthenticate
          logger.info "passed oauthenticate"
          if authorized?
            logger.info "passed authorized"
            return true
          else
            logger.info "failed authorized"
            invalid_oauth_response
          end
        else
          logger.info "failed oauthenticate"
          
          invalid_oauth_response
        end
      end
      
      # This requies that you have an acts_as_authenticated compatible authentication plugin installed
      def login_or_oauth_required
        if oauthenticate
          if authorized?
            return true
          else
            invalid_oauth_response
          end
        else
          login_required
        end
      end
      
      
      # verifies a request token request
      def verify_oauth_consumer_signature
        begin
          valid = ClientApplication.verify_request(request) do |token, consumer_key|
            @current_client_application = ClientApplication.find_by_key(consumer_key)

            # return the token secret and the consumer secret
            [nil, @current_client_application.secret]
          end
        rescue
          valid=false
        end

        invalid_oauth_response unless valid
      end

      def verify_oauth_request_token
        verify_oauth_signature && current_token.is_a?(RequestToken)
      end

      def invalid_oauth_response(code=401,message="Invalid OAuth Request")
        render :text => message, :status => code
      end

      private
      
      def current_token=(token)
        @current_token=token
        if @current_token
          @current_user=@current_token.user
          @current_client_application=@current_token.client_application 
        end
        @current_token
      end
      
      # Implement this for your own application using app-specific models
      def verify_oauth_signature
        begin
          valid = ClientApplication.verify_request(request) do |request|
            self.current_token = ClientApplication.find_token(request.token)
            logger.info "self=#{self.class.to_s}"
            logger.info "token=#{self.current_token}"
            # return the token secret and the consumer secret
            [(current_token.nil? ? nil : current_token.secret), (current_client_application.nil? ? nil : current_client_application.secret)]
          end
          # reset @current_user to clear state for restful_...._authentication
          @current_user = nil if (!valid)
          valid
        rescue
          false
        end
      end
    end
  end
end