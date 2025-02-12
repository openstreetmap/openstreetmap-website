require "test_helper"

module Api
  class ChangesetCommentsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/changeset/1/comment", :method => :post },
        { :controller => "api/changeset_comments", :action => "create", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/comment.json", :method => :post },
        { :controller => "api/changeset_comments", :action => "create", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/comment/1/hide", :method => :post },
        { :controller => "api/changeset_comments", :action => "destroy", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/comment/1/hide.json", :method => :post },
        { :controller => "api/changeset_comments", :action => "destroy", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/comment/1/unhide", :method => :post },
        { :controller => "api/changeset_comments", :action => "restore", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/comment/1/unhide.json", :method => :post },
        { :controller => "api/changeset_comments", :action => "restore", :id => "1", :format => "json" }
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

      auth_header = bearer_authorization_header user

      assert_difference "ChangesetComment.count", 1 do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post changeset_comment_path(private_user_closed_changeset, :text => "This is a comment"), :headers => auth_header
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
            post changeset_comment_path(changeset, :text => "This is a comment"), :headers => auth_header
          end
        end
      end
      assert_response :success

      email = ActionMailer::Base.deliveries.first
      assert_equal 1, email.to.length
      assert_equal "[OpenStreetMap] #{user.display_name} has commented on one of your changesets", email.subject
      assert_equal private_user.email, email.to.first

      ActionMailer::Base.deliveries.clear

      auth_header = bearer_authorization_header user2

      assert_difference "ChangesetComment.count", 1 do
        assert_difference "ActionMailer::Base.deliveries.size", 2 do
          perform_enqueued_jobs do
            post changeset_comment_path(changeset, :text => "This is a comment"), :headers => auth_header
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
      post changeset_comment_path(create(:changeset, :closed), :text => "This is a comment")
      assert_response :unauthorized

      auth_header = bearer_authorization_header

      # bad changeset id
      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(999111, :text => "This is a comment"), :headers => auth_header
      end
      assert_response :not_found

      # not closed changeset
      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(create(:changeset), :text => "This is a comment"), :headers => auth_header
      end
      assert_response :conflict

      # no text
      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(create(:changeset, :closed)), :headers => auth_header
      end
      assert_response :bad_request

      # empty text
      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(create(:changeset, :closed), :text => ""), :headers => auth_header
      end
      assert_response :bad_request
    end

    ##
    # create comment rate limit for new users
    def test_create_comment_new_user_rate_limit
      changeset = create(:changeset, :closed)
      user = create(:user)

      auth_header = bearer_authorization_header user

      assert_difference "ChangesetComment.count", Settings.initial_changeset_comments_per_hour do
        1.upto(Settings.initial_changeset_comments_per_hour) do |count|
          post changeset_comment_path(changeset, :text => "Comment #{count}"), :headers => auth_header
          assert_response :success
        end
      end

      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(changeset, :text => "One comment too many"), :headers => auth_header
        assert_response :too_many_requests
      end
    end

    ##
    # create comment rate limit for experienced users
    def test_create_comment_experienced_user_rate_limit
      changeset = create(:changeset, :closed)
      user = create(:user)
      create_list(:changeset_comment, Settings.comments_to_max_changeset_comments, :author_id => user.id, :created_at => Time.now.utc - 1.day)

      auth_header = bearer_authorization_header user

      assert_difference "ChangesetComment.count", Settings.max_changeset_comments_per_hour do
        1.upto(Settings.max_changeset_comments_per_hour) do |count|
          post changeset_comment_path(changeset, :text => "Comment #{count}"), :headers => auth_header
          assert_response :success
        end
      end

      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(changeset, :text => "One comment too many"), :headers => auth_header
        assert_response :too_many_requests
      end
    end

    ##
    # create comment rate limit for reported users
    def test_create_comment_reported_user_rate_limit
      changeset = create(:changeset, :closed)
      user = create(:user)
      create(:issue_with_reports, :reportable => user, :reported_user => user)

      auth_header = bearer_authorization_header user

      assert_difference "ChangesetComment.count", Settings.initial_changeset_comments_per_hour / 2 do
        1.upto(Settings.initial_changeset_comments_per_hour / 2) do |count|
          post changeset_comment_path(changeset, :text => "Comment #{count}"), :headers => auth_header
          assert_response :success
        end
      end

      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(changeset, :text => "One comment too many"), :headers => auth_header
        assert_response :too_many_requests
      end
    end

    ##
    # create comment rate limit for moderator users
    def test_create_comment_moderator_user_rate_limit
      changeset = create(:changeset, :closed)
      user = create(:moderator_user)

      auth_header = bearer_authorization_header user

      assert_difference "ChangesetComment.count", Settings.moderator_changeset_comments_per_hour do
        1.upto(Settings.moderator_changeset_comments_per_hour) do |count|
          post changeset_comment_path(changeset, :text => "Comment #{count}"), :headers => auth_header
          assert_response :success
        end
      end

      assert_no_difference "ChangesetComment.count" do
        post changeset_comment_path(changeset, :text => "One comment too many"), :headers => auth_header
        assert_response :too_many_requests
      end
    end

    ##
    # test hide comment fail
    def test_destroy_comment_fail
      # unauthorized
      comment = create(:changeset_comment)
      assert comment.visible

      post changeset_comment_hide_path(comment)
      assert_response :unauthorized
      assert comment.reload.visible

      auth_header = bearer_authorization_header

      # not a moderator
      post changeset_comment_hide_path(comment), :headers => auth_header
      assert_response :forbidden
      assert comment.reload.visible

      auth_header = bearer_authorization_header create(:moderator_user)

      # bad comment id
      post changeset_comment_hide_path(999111), :headers => auth_header
      assert_response :not_found
      assert comment.reload.visible
    end

    ##
    # test hide comment succes
    def test_hide_comment_success
      comment = create(:changeset_comment)
      assert comment.visible

      auth_header = bearer_authorization_header create(:moderator_user)

      post changeset_comment_hide_path(comment), :headers => auth_header
      assert_response :success
      assert_not comment.reload.visible
    end

    ##
    # test unhide comment fail
    def test_restore_comment_fail
      # unauthorized
      comment = create(:changeset_comment, :visible => false)
      assert_not comment.visible

      post changeset_comment_unhide_path(comment)
      assert_response :unauthorized
      assert_not comment.reload.visible

      auth_header = bearer_authorization_header

      # not a moderator
      post changeset_comment_unhide_path(comment), :headers => auth_header
      assert_response :forbidden
      assert_not comment.reload.visible

      auth_header = bearer_authorization_header create(:moderator_user)

      # bad comment id
      post changeset_comment_unhide_path(999111), :headers => auth_header
      assert_response :not_found
      assert_not comment.reload.visible
    end

    ##
    # test unhide comment succes
    def test_unhide_comment_success
      comment = create(:changeset_comment, :visible => false)
      assert_not comment.visible

      auth_header = bearer_authorization_header create(:moderator_user)

      post changeset_comment_unhide_path(comment), :headers => auth_header
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
      auth_header = bearer_authorization_header(user, :scopes => %w[write_api])
      changeset = create(:changeset, :closed)

      assert_difference "ChangesetComment.count", 0 do
        post changeset_comment_path(changeset), :params => { :text => "This is a comment" }, :headers => auth_header
      end
      assert_response :forbidden

      # Try again, after agreement with the terms
      user.terms_agreed = Time.now.utc
      user.save!

      assert_difference "ChangesetComment.count", 1 do
        post changeset_comment_path(changeset), :params => { :text => "This is a comment" }, :headers => auth_header
      end
      assert_response :success
    end
  end
end
