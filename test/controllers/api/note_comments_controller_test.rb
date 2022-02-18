require "test_helper"

module Api
  class NoteCommentsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/note/comment/1/hide", :method => :post },
        { :controller => "api/note_comments", :action => "destroy", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/note/comment/1/unhide", :method => :post },
        { :controller => "api/note_comments", :action => "restore", :id => "1" }
      )
    end

    ##
    # test hide comment fail
    def test_hide_comment_fail
      note = create(:note_with_comments) # implicitly creates an opening comment
      comment = create(:note_comment, :note => note, :body => "Note comment", :event => :commented)

      assert comment.visible
      assert_equal(2, note.comments.count)
      assert note.comments.first.visible
      assert note.comments.last.visible
      assert_equal("opened", note.comments.first.event)
      assert_equal("commented", note.comments.last.event)

      # unauthorized
      post note_comment_hide_path(:id => comment)
      assert_response :unauthorized
      assert comment.reload.visible

      auth_header = basic_authorization_header create(:user).email, "test"

      # not a moderator
      post note_comment_hide_path(:id => comment), :headers => auth_header
      assert_response :forbidden
      assert comment.reload.visible

      auth_header = basic_authorization_header create(:moderator_user).email, "test"

      # bad comment id
      post note_comment_hide_path(:id => 9191), :headers => auth_header
      assert_response :not_found
      assert comment.reload.visible

      # cannot hide opening comment
      post note_comment_hide_path(:id => note.comments.first), :headers => auth_header
      assert_response :bad_request
      assert note.comments.first.reload.visible
    end

    ##
    # test hide comment succes
    def test_hide_comment_success
      note = create(:note_with_comments)
      comment = create(:note_comment, :note => note, :body => "Note comment", :event => :commented)
      assert comment.visible

      auth_header = basic_authorization_header create(:moderator_user).email, "test"

      post note_comment_hide_path(:id => comment, :format => "xml"), :headers => auth_header
      assert_response :success
      assert_not comment.reload.visible
    end

    ##
    # test unhide comment fail
    def test_restore_comment_fail
      note = create(:note_with_comments)
      comment = create(:note_comment, :note => note, :visible => false, :body => "Note comment", :event => :commented)
      assert_not comment.visible

      # unauthorized
      post note_comment_unhide_path(:id => comment)
      assert_response :unauthorized
      assert_not comment.reload.visible

      auth_header = basic_authorization_header create(:user).email, "test"

      # not a moderator
      post note_comment_unhide_path(:id => comment), :headers => auth_header
      assert_response :forbidden
      assert_not comment.reload.visible

      auth_header = basic_authorization_header create(:moderator_user).email, "test"

      # bad comment id
      post note_comment_unhide_path(:id => 999111), :headers => auth_header
      assert_response :not_found
      assert_not comment.reload.visible

      # cannot unhide opening comment
      post note_comment_hide_path(:id => note.comments.first), :headers => auth_header
      assert_response :bad_request
      assert_equal("opened", note.comments.first.event)
      assert note.comments.first.reload.visible
    end

    ##
    # test unhide comment succes
    def test_unhide_comment_success
      note = create(:note_with_comments)
      comment = create(:note_comment, :note => note, :visible => false, :body => "Note comment", :event => :commented)
      assert_not comment.visible

      auth_header = basic_authorization_header create(:moderator_user).email, "test"

      post note_comment_unhide_path(:id => comment, :format => "xml"), :headers => auth_header
      assert_response :success
      assert comment.reload.visible
    end
  end
end
