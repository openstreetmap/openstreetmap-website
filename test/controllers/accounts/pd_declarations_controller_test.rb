# frozen_string_literal: true

require "test_helper"

module Accounts
  class PdDeclarationsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/account/pd_declaration", :method => :get },
        { :controller => "accounts/pd_declarations", :action => "show" }
      )
      assert_routing(
        { :path => "/account/pd_declaration", :method => :post },
        { :controller => "accounts/pd_declarations", :action => "create" }
      )
    end

    def test_show_not_logged_in
      get account_pd_declaration_path

      assert_redirected_to login_path(:referer => account_pd_declaration_path)
    end

    def test_show_agreed
      user = create(:user)
      session_for(user)

      get account_pd_declaration_path

      assert_response :success
    end

    def test_create_not_logged_in
      post account_pd_declaration_path

      assert_response :forbidden
    end

    def test_create_unconfirmed
      # OHM variant: account creation requires edits be in the Public Domain
      user = create(:user)
      session_for(user)

      post account_pd_declaration_path

      assert_redirected_to account_path
      assert_nil flash[:notice]
      assert_equal "You have already declared that you consider your edits to be in the Public Domain.", flash[:warning]

      user.reload
      assert_predicate user, :consider_pd
    end

    def test_create_confirmed
      # OHM variant: account creation requires edits be in the Public Domain
      user = create(:user)
      session_for(user)

      post account_pd_declaration_path, :params => { :consider_pd => true }

      assert_nil flash[:notice]
      assert_equal "You have already declared that you consider your edits to be in the Public Domain.", flash[:warning]

      user.reload
      assert_predicate user, :consider_pd
    end

    def test_create_already_declared_unconfirmed
      user = create(:user, :consider_pd => true)
      session_for(user)

      post account_pd_declaration_path

      assert_nil flash[:notice]
      assert_equal "You have already declared that you consider your edits to be in the Public Domain.", flash[:warning]

      user.reload
      assert_predicate user, :consider_pd
    end

    def test_create_already_declared_confirmed
      user = create(:user, :consider_pd => true)
      session_for(user)

      post account_pd_declaration_path, :params => { :consider_pd => true }

      assert_nil flash[:notice]
      assert_equal "You have already declared that you consider your edits to be in the Public Domain.", flash[:warning]

      user.reload
      assert_predicate user, :consider_pd
    end
  end
end
