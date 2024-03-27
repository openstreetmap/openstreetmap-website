require "test_helper"

class ChangesetCommentsFeedsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/changeset/1/comments/feed", :method => :get },
      { :controller => "changeset_comments_feeds", :action => "show", :changeset_id => "1", :format => "rss" }
    )
    assert_routing(
      { :path => "/history/comments/feed", :method => :get },
      { :controller => "changeset_comments_feeds", :action => "show", :format => "rss" }
    )
  end

  def test_show
    changeset1 = create(:changeset, :closed)
    changeset2 = create(:changeset, :closed)
    create_list(:changeset_comment, 1, :changeset => changeset1)
    create_list(:changeset_comment, 2, :changeset => changeset2)

    get changeset_comments_feed_path(:format => "rss")
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end

    get changeset_comments_feed_path(:format => "rss", :limit => 2)
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 2
      end
    end

    get changeset_changeset_comments_feed_path(changeset1, :format => "rss")
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 1
      end
    end

    get changeset_changeset_comments_feed_path(changeset2, :format => "rss")
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 2
      end
    end
  end

  def test_show_bad_limit
    get changeset_comments_feed_path(:format => "rss", :limit => 0)
    assert_response :bad_request

    get changeset_comments_feed_path(:format => "rss", :limit => 100001)
    assert_response :bad_request
  end
end
