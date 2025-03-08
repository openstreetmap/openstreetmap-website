require "test_helper"

class DiaryCommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    # Create the default language for diary entries
    create(:language, :code => "en")
  end

  def test_routes
    assert_routing(
      { :path => "/user/username/diary/1/comments", :method => :post },
      { :controller => "diary_comments", :action => "create", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/diary_comments/2/hide", :method => :post },
      { :controller => "diary_comments", :action => "hide", :comment => "2" }
    )
    assert_routing(
      { :path => "/diary_comments/2/unhide", :method => :post },
      { :controller => "diary_comments", :action => "unhide", :comment => "2" }
    )
  end

  def test_create
    user = create(:user)
    other_user = create(:user)
    entry = create(:diary_entry, :user => user)
    create(:diary_entry_subscription, :diary_entry => entry, :user => user)

    # Make sure that you are denied when you are not logged in
    post comment_diary_entry_path(entry.user, entry)
    assert_response :forbidden

    session_for(other_user)

    # Verify that you get a not found error, when you pass a bogus id
    post comment_diary_entry_path(entry.user, :id => 9999)
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => "No entry with the id: 9999", :count => 1
    end

    # Now try an invalid comment with an empty body
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_difference "DiaryComment.count" do
        assert_no_difference "entry.subscribers.count" do
          perform_enqueued_jobs do
            post comment_diary_entry_path(entry.user, entry, :diary_comment => { :body => "" })
          end
        end
      end
    end
    assert_response :success
    assert_template :new
    assert_match(/img-src \* data:;/, @response.headers["Content-Security-Policy-Report-Only"])

    # Now try again with the right id
    assert_difference "ActionMailer::Base.deliveries.size", entry.subscribers.count do
      assert_difference "DiaryComment.count", 1 do
        assert_difference "entry.subscribers.count", 1 do
          perform_enqueued_jobs do
            post comment_diary_entry_path(entry.user, entry, :diary_comment => { :body => "New comment" })
          end
        end
      end
    end
    comment = DiaryComment.last
    assert_redirected_to diary_entry_path(entry.user, entry, :anchor => "comment#{comment.id}")
    email = ActionMailer::Base.deliveries.first
    assert_equal [user.email], email.to
    assert_equal "[OpenStreetMap] #{other_user.display_name} commented on a diary entry", email.subject
    assert_match(/New comment/, email.text_part.decoded)
    assert_match(/New comment/, email.html_part.decoded)
    assert_equal entry.id, comment.diary_entry_id
    assert_equal other_user.id, comment.user_id
    assert_equal "New comment", comment.body

    # Now show the diary entry, and check the new comment is present
    get diary_entry_path(entry.user, entry)
    assert_response :success
    assert_select ".diary-comment", :count => 1 do
      assert_select "#comment#{comment.id}", :count => 1 do
        assert_select "a[href='/user/#{ERB::Util.u(other_user.display_name)}']", :text => other_user.display_name, :count => 1
      end
      assert_select ".richtext", :text => /New comment/, :count => 1
    end
  end

  def test_create_spammy
    user = create(:user)
    other_user = create(:user)
    entry = create(:diary_entry, :user => user)
    create(:diary_entry_subscription, :diary_entry => entry, :user => user)

    session_for(other_user)

    # Generate some spammy content
    spammy_text = 1.upto(50).map { |n| "http://example.com/spam#{n}" }.join(" ")

    # Try creating a spammy comment
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "DiaryComment.count", 1 do
        perform_enqueued_jobs do
          post comment_diary_entry_path(entry.user, entry, :diary_comment => { :body => spammy_text })
        end
      end
    end
    comment = DiaryComment.last
    assert_redirected_to diary_entry_path(entry.user, entry, :anchor => "comment#{comment.id}")
    email = ActionMailer::Base.deliveries.first
    assert_equal [user.email], email.to
    assert_equal "[OpenStreetMap] #{other_user.display_name} commented on a diary entry", email.subject
    assert_match %r{http://example.com/spam}, email.text_part.decoded
    assert_match %r{http://example.com/spam}, email.html_part.decoded
    assert_equal entry.id, comment.diary_entry_id
    assert_equal other_user.id, comment.user_id
    assert_equal spammy_text, comment.body
    assert_equal "suspended", User.find(other_user.id).status

    # Follow the redirect
    get diary_entries_path(:display_name => user.display_name)
    assert_redirected_to :controller => :users, :action => :suspended

    # Now show the diary entry, and check the new comment is not present
    get diary_entry_path(entry.user, entry)
    assert_response :success
    assert_select ".diary-comment", :count => 0
  end

  def test_hide
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)

    # Try without logging in
    post hide_diary_comment_path(diary_comment)
    assert_response :forbidden
    assert DiaryComment.find(diary_comment.id).visible

    # Now try as a normal user
    session_for(user)
    post hide_diary_comment_path(diary_comment)
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert DiaryComment.find(diary_comment.id).visible

    # Try as a moderator
    session_for(create(:moderator_user))
    post hide_diary_comment_path(diary_comment)
    assert_redirected_to diary_entry_path(user, diary_entry)
    assert_not DiaryComment.find(diary_comment.id).visible

    # Reset
    diary_comment.reload.update(:visible => true)

    # Finally try as an administrator
    session_for(create(:administrator_user))
    post hide_diary_comment_path(diary_comment)
    assert_redirected_to diary_entry_path(user, diary_entry)
    assert_not DiaryComment.find(diary_comment.id).visible
  end

  def test_unhide
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry, :visible => false)

    # Try without logging in
    post unhide_diary_comment_path(diary_comment)
    assert_response :forbidden
    assert_not DiaryComment.find(diary_comment.id).visible

    # Now try as a normal user
    session_for(user)
    post unhide_diary_comment_path(diary_comment)
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_not DiaryComment.find(diary_comment.id).visible

    # Now try as a moderator
    session_for(create(:moderator_user))
    post unhide_diary_comment_path(diary_comment)
    assert_redirected_to diary_entry_path(user, diary_entry)
    assert DiaryComment.find(diary_comment.id).visible

    # Reset
    diary_comment.reload.update(:visible => true)

    # Finally try as an administrator
    session_for(create(:administrator_user))
    post unhide_diary_comment_path(diary_comment)
    assert_redirected_to diary_entry_path(user, diary_entry)
    assert DiaryComment.find(diary_comment.id).visible
  end
end
