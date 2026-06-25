# frozen_string_literal: true

require "test_helper"

module Accounts
  class AuthDeletionsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/auth/provider/delete", :method => :get },
        { :controller => "accounts/auth_deletions", :action => "show", :provider => "provider" }
      )
      assert_routing(
        { :path => "/auth/provider/delete", :method => :post },
        { :controller => "accounts/auth_deletions", :action => "create", :provider => "provider" }
      )
    end

    ##
    # test showing status of a facebook deletion request
    def test_show_facebook
      user = create(:user, :auth_provider => "facebook", :auth_uid => "12345")
      confirmation_code = Rails.application.message_verifier(:social_login_deletion).generate([user.auth_uid, Time.now.to_i])

      get auth_delete_path(:provider => "facebook", :confirmation_code => confirmation_code)
      assert_response :success
      assert_select "p", /^Data for Facebook ID 12345 was removed at .* and it was disconnected from the associated OpenStreetMap account\.$/
    end

    ##
    # test showing status of a facebook deletion request with no code
    def test_show_facebook_no_code
      get auth_delete_path(:provider => "facebook")
      assert_response :bad_request
    end

    ##
    # test showing status of a facebook deletion request with an invalid code
    def test_show_facebook_invalid_code
      get auth_delete_path(:provider => "facebook", :confirmation_code => "invalid")
      assert_response :bad_request
    end

    ##
    # test creation of a facebook deletion request
    def test_create_facebook
      user = create(:user, :auth_provider => "facebook", :auth_uid => "12345")

      payload = Base64.urlsafe_encode64(
        JSON.generate(
          :algorithm => "HMAC-SHA256",
          :expires => Time.now.to_i + 3600,
          :issued_at => Time.now.to_i,
          :user_id => "12345"
        )
      )
      signature = OpenSSL::HMAC.digest("SHA256", Settings.facebook_auth_secret, payload)
      encoded_signature = Base64.urlsafe_encode64(signature)
      signed_request = [encoded_signature, payload].join(".")

      post auth_delete_path(:provider => "facebook"), :params => { :signed_request => signed_request }
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_not_nil js["confirmation_code"]
      assert_equal auth_delete_url(:provider => "facebook", :confirmation_code => js["confirmation_code"]), js["url"]

      assert_nil user.reload.auth_provider
      assert_nil user.reload.auth_uid
    end

    ##
    # test creation of a facebook deletion request with an invalid signature
    def test_create_facebook_bad_signature
      create(:user, :auth_provider => "facebook", :auth_uid => "12345")

      payload = Base64.urlsafe_encode64(
        JSON.generate(
          :algorithm => "HMAC-SHA256",
          :expires => Time.now.to_i + 3600,
          :issued_at => Time.now.to_i,
          :user_id => "12345"
        )
      )
      signature = OpenSSL::HMAC.digest("SHA256", "invalid secret", payload)
      encoded_signature = Base64.urlsafe_encode64(signature)
      signed_request = [encoded_signature, payload].join(".")

      post auth_delete_path(:provider => "facebook"), :params => { :signed_request => signed_request }
      assert_response :bad_request
    end

    ##
    # test creation of a facebook deletion request for an unassociated ID
    def test_create_facebook_not_associated
      payload = Base64.urlsafe_encode64(
        JSON.generate(
          :algorithm => "HMAC-SHA256",
          :expires => Time.now.to_i + 3600,
          :issued_at => Time.now.to_i,
          :user_id => "12345"
        )
      )
      signature = OpenSSL::HMAC.digest("SHA256", Settings.facebook_auth_secret, payload)
      encoded_signature = Base64.urlsafe_encode64(signature)
      signed_request = [encoded_signature, payload].join(".")

      post auth_delete_path(:provider => "facebook"), :params => { :signed_request => signed_request }
      assert_response :not_found
    end

    ##
    # test creation of a deletion request for an unsupported provider
    def test_create_unsupported
      post auth_delete_path(:provider => "unsupported")
      assert_response :not_found
    end
  end
end
