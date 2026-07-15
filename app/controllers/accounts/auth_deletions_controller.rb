# frozen_string_literal: true

module Accounts
  class AuthDeletionsController < ApplicationController
    layout :site_layout

    before_action :set_locale

    authorize_resource :class => :auth_deletion

    def show
      @auth_provider = params.expect(:provider)
      @auth_uid, @time = Rails
                         .application
                         .message_verifier(:social_login_deletion)
                         .verify(params.expect(:confirmation_code))
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      head :bad_request
    end

    def create
      if params.expect(:provider) == "facebook"
        create_facebook
      else
        head :not_found
      end
    end

    private

    def create_facebook
      encoded_signature, payload = params.expect(:signed_request).split(".", 2)
      signature = Base64.urlsafe_decode64(encoded_signature)

      raise ActionController::BadRequest unless signature == OpenSSL::HMAC.digest("SHA256", Settings.facebook_auth_secret, payload)

      data = JSON.parse(Base64.urlsafe_decode64(payload))
      user = User.find_by!(:auth_provider => "facebook", :auth_uid => data["user_id"])

      user.auth_provider = nil
      user.auth_uid = nil
      user.save!

      @confirmation_code = Rails
                           .application
                           .message_verifier(:social_login_deletion)
                           .generate([data["user_id"], Time.now.to_i])

      render :formats => [:json]
    end
  end
end
