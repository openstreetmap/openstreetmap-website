require "test_helper"

module Accounts
  class TermsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/account/terms", :method => :get },
        { :controller => "accounts/terms", :action => "show" }
      )
      assert_routing(
        { :path => "/account/terms", :method => :put },
        { :controller => "accounts/terms", :action => "update" }
      )

      get "/user/terms"
      assert_redirected_to "/account/terms"
    end

    def test_show_not_logged_in
      get account_terms_path

      assert_redirected_to login_path(:referer => account_terms_path)
    end

    def test_show_agreed
      user = create(:user, :terms_seen => true, :terms_agreed => Date.yesterday)
      session_for(user)

      get account_terms_path
      assert_response :success
    end

    def test_show_not_seen_without_referer
      user = create(:user, :terms_seen => false, :terms_agreed => nil)
      session_for(user)

      get account_terms_path
      assert_response :success
    end

    def test_show_not_seen_with_referer
      user = create(:user, :terms_seen => false, :terms_agreed => nil)
      session_for(user)

      get account_terms_path(:referer => "/test")
      assert_response :success
    end

    def test_update_decline
      user = create(:user, :terms_seen => false, :terms_agreed => nil, :tou_agreed => nil)
      session_for(user)

      freeze_time do
        put account_terms_path

        assert_redirected_to account_path
        assert_equal({ :partial => "accounts/terms/terms_declined_flash" }, flash[:notice])

        user.reload
        assert user.terms_seen
        assert_nil user.terms_agreed
        assert_nil user.tou_agreed
      end
    end

    def test_update_not_seen
      user = create(:user, :terms_seen => false, :terms_agreed => nil, :tou_agreed => nil)
      session_for(user)

      freeze_time do
        put account_terms_path, :params => { :read_ct => 1, :read_tou => 1 }

        assert_redirected_to account_path
        assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

        user.reload
        assert user.terms_seen
        assert_equal Time.now.utc, user.terms_agreed
        assert_equal Time.now.utc, user.tou_agreed
      end
    end

    def test_update_not_seen_with_referer
      user = create(:user, :terms_seen => false, :terms_agreed => nil, :tou_agreed => nil)
      session_for(user)

      freeze_time do
        put account_terms_path, :params => { :referer => "/test", :read_ct => 1, :read_tou => 1 }

        assert_redirected_to "/test"
        assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

        user.reload
        assert user.terms_seen
        assert_equal Time.now.utc, user.terms_agreed
        assert_equal Time.now.utc, user.tou_agreed
      end
    end

    def test_update_previously_accepted
      user = create(:user, :terms_seen => true, :terms_agreed => Date.yesterday, :tou_agreed => Date.yesterday)
      session_for(user)

      freeze_time do
        put account_terms_path, :params => { :read_ct => 1, :read_tou => 1 }

        assert_redirected_to account_path
        assert_equal "Thanks for accepting the new contributor terms!", flash[:notice]

        user.reload
        assert user.terms_seen
        assert_equal Time.now.utc, user.terms_agreed
        assert_equal Time.now.utc, user.tou_agreed
      end
    end

    # Check that if you haven't seen the terms, and make a request that requires authentication,
    # that your request is redirected to view the terms
    def test_terms_not_seen_redirection
      user = create(:user, :terms_seen => false, :terms_agreed => nil)
      session_for(user)

      get account_path
      assert_redirected_to account_terms_path(:referer => account_path)
    end
  end
end
