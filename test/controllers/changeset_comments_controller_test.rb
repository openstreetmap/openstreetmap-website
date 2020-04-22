require "test_helper"

class ChangesetCommentsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/changeset/1/comments/feed", :method => :get },
      { :controller => "changeset_comments", :action => "index", :id => "1", :format => "rss" }
    )
    assert_routing(
      { :path => "/history/comments/feed", :method => :get },
      { :controller => "changeset_comments", :action => "index", :format => "rss" }
    )
  end

  ##
  # test comments feed
  def test_feed
    changeset = create(:changeset, :closed)
    create_list(:changeset_comment, 3, :changeset => changeset)

    get changesets_comments_feed_path(:format => "rss")
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end

    get changesets_comments_feed_path(:format => "rss", :limit => 2)
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 2
      end
    end

    get changeset_comments_feed_path(:id => changeset.id, :format => "rss")
    assert_response :success
    assert_equal "application/rss+xml", @response.media_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end
  end

  ##
  # test comments feed
  def test_feed_bad_limit
    get changesets_comments_feed_path(:format => "rss", :limit => 0)
    assert_response :bad_request

    get changesets_comments_feed_path(:format => "rss", :limit => 100001)
    assert_response :bad_request
  end
end
