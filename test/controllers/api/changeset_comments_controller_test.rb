require "test_helper"

module Api
  class ChangesetCommentsControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/changeset/1/comment", :method => :post },
        { :controller => "api/changeset_comments", :action => "create", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/comment/1/hide", :method => :post },
        { :controller => "api/changeset_comments", :action => "destroy", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/comment/1/unhide", :method => :post },
        { :controller => "api/changeset_comments", :action => "restore", :id => "1" }
      )
    end

    ##
    # create comment success
    def test_create_comment_success
      user = create(:user)
      user2 = create(:user)
      private_user = create(:user, :data_public => false)
      suspended_user = create(:user, :suspended)
      deleted_user = create(:user, :deleted)
      private_user_closed_changeset = create(:changeset, :closed, :user => private_user)

      basic_authorization user.email, "test"

      assert_difference "ChangesetComment.count", 1 do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post :create, :params => { :id => private_user_closed_changeset.id, :text => "This is a comment" }
          end
        end
      end
      assert_response :success

      changeset = create(:changeset, :closed, :user => private_user)
      changeset.subscribers.push(private_user)
      changeset.subscribers.push(user)
      changeset.subscribers.push(suspended_user)
      changeset.subscribers.push(deleted_user)

      assert_difference "ChangesetComment.count", 1 do
        assert_difference "ActionMailer::Base.deliveries.size", 1 do
          perform_enqueued_jobs do
            post :create, :params => { :id => changeset.id, :text => "This is a comment" }
          end
        end
      end
      assert_response :success

      email = ActionMailer::Base.deliveries.first
      assert_equal 1, email.to.length
      assert_equal "[OpenStreetMap] #{user.display_name} has commented on one of your changesets", email.subject
      assert_equal private_user.email, email.to.first

      ActionMailer::Base.deliveries.clear

      basic_authorization user2.email, "test"

      assert_difference "ChangesetComment.count", 1 do
        assert_difference "ActionMailer::Base.deliveries.size", 2 do
          perform_enqueued_jobs do
            post :create, :params => { :id => changeset.id, :text => "This is a comment" }
          end
        end
      end
      assert_response :success

      email = ActionMailer::Base.deliveries.find { |e| e.to.first == private_user.email }
      assert_not_nil email
      assert_equal 1, email.to.length
      assert_equal "[OpenStreetMap] #{user2.display_name} has commented on one of your changesets", email.subject

      email = ActionMailer::Base.deliveries.find { |e| e.to.first == user.email }
      assert_not_nil email
      assert_equal 1, email.to.length
      assert_equal "[OpenStreetMap] #{user2.display_name} has commented on a changeset you are interested in", email.subject

      ActionMailer::Base.deliveries.clear
    end

    ##
    # create comment fail
    def test_create_comment_fail
      # unauthorized
      post :create, :params => { :id => create(:changeset, :closed).id, :text => "This is a comment" }
      assert_response :unauthorized

      basic_authorization create(:user).email, "test"

      # bad changeset id
      assert_no_difference "ChangesetComment.count" do
        post :create, :params => { :id => 999111, :text => "This is a comment" }
      end
      assert_response :not_found

      # not closed changeset
      assert_no_difference "ChangesetComment.count" do
        post :create, :params => { :id => create(:changeset).id, :text => "This is a comment" }
      end
      assert_response :conflict

      # no text
      assert_no_difference "ChangesetComment.count" do
        post :create, :params => { :id => create(:changeset, :closed).id }
      end
      assert_response :bad_request

      # empty text
      assert_no_difference "ChangesetComment.count" do
        post :create, :params => { :id => create(:changeset, :closed).id, :text => "" }
      end
      assert_response :bad_request
    end

    ##
    # test hide comment fail
    def test_destroy_comment_fail
      # unauthorized
      comment = create(:changeset_comment)
      assert comment.visible

      post :destroy, :params => { :id => comment.id }
      assert_response :unauthorized
      assert comment.reload.visible

      basic_authorization create(:user).email, "test"

      # not a moderator
      post :destroy, :params => { :id => comment.id }
      assert_response :forbidden
      assert comment.reload.visible

      basic_authorization create(:moderator_user).email, "test"

      # bad comment id
      post :destroy, :params => { :id => 999111 }
      assert_response :not_found
      assert comment.reload.visible
    end

    ##
    # test hide comment succes
    def test_hide_comment_success
      comment = create(:changeset_comment)
      assert comment.visible

      basic_authorization create(:moderator_user).email, "test"

      post :destroy, :params => { :id => comment.id }
      assert_response :success
      assert_not comment.reload.visible
    end

    ##
    # test unhide comment fail
    def test_restore_comment_fail
      # unauthorized
      comment = create(:changeset_comment, :visible => false)
      assert_not comment.visible

      post :restore, :params => { :id => comment.id }
      assert_response :unauthorized
      assert_not comment.reload.visible

      basic_authorization create(:user).email, "test"

      # not a moderator
      post :restore, :params => { :id => comment.id }
      assert_response :forbidden
      assert_not comment.reload.visible

      basic_authorization create(:moderator_user).email, "test"

      # bad comment id
      post :restore, :params => { :id => 999111 }
      assert_response :not_found
      assert_not comment.reload.visible
    end

    ##
    # test unhide comment succes
    def test_unhide_comment_success
      comment = create(:changeset_comment, :visible => false)
      assert_not comment.visible

      basic_authorization create(:moderator_user).email, "test"

      post :restore, :params => { :id => comment.id }
      assert_response :success
      assert comment.reload.visible
    end

    # This test ensures that token capabilities behave correctly for a method that
    # requires the terms to have been agreed.
    # (This would be better as an integration or system testcase, since the changeset_comment
    # create method is simply a stand-in for any method that requires terms agreement.
    # But writing oauth tests is hard, and so it's easier to put in a controller test.)
    def test_api_write_and_terms_agreed_via_token
      user = create(:user, :terms_agreed => nil)
      token = create(:access_token, :user => user, :allow_write_api => true)
      changeset = create(:changeset, :closed)

      # Hack together an oauth request - an alternative would be to sign the request properly
      @request.env["oauth.version"] = 1
      @request.env["oauth.strategies"] = [:token]
      @request.env["oauth.token"] = token

      assert_difference "ChangesetComment.count", 0 do
        post :create, :params => { :id => changeset.id, :text => "This is a comment" }
      end
      assert_response :forbidden

      # Try again, after agreement with the terms
      user.terms_agreed = Time.now
      user.save!

      assert_difference "ChangesetComment.count", 1 do
        post :create, :params => { :id => changeset.id, :text => "This is a comment" }
      end
      assert_response :success
    end

    # This test does the same as above, but with basic auth, to similarly test that the
    # abilities take into account terms agreement too.
    def test_api_write_and_terms_agreed_via_basic_auth
      user = create(:user, :terms_agreed => nil)
      changeset = create(:changeset, :closed)

      basic_authorization user.email, "test"

      assert_difference "ChangesetComment.count", 0 do
        post :create, :params => { :id => changeset.id, :text => "This is a comment" }
      end
      assert_response :forbidden

      # Try again, after agreement with the terms
      user.terms_agreed = Time.now
      user.save!

      assert_difference "ChangesetComment.count", 1 do
        post :create, :params => { :id => changeset.id, :text => "This is a comment" }
      end
      assert_response :success
    end
  end
end
