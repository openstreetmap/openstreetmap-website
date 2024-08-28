require "test_helper"

module Feeds
  class ChangesetCommentsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/changeset/1/comments/feed", :method => :get },
        { :controller => "feeds/changeset_comments", :action => "index", :changeset_id => "1", :format => "rss" }
      )
      assert_routing(
        { :path => "/history/comments/feed", :method => :get },
        { :controller => "feeds/changeset_comments", :action => "index", :format => "rss" }
      )
    end

    ##
    # test comments feed
    def test_feed
      changeset = create(:changeset, :closed)
      create_list(:changeset_comment, 3, :changeset => changeset)

      get feeds_changeset_comments_path(:format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 3
        end
      end

      get feeds_changeset_comments_path(:format => "rss", :limit => 2)
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 2
        end
      end

      get changeset_feeds_changeset_comments_path(changeset, :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      last_comment_id = -1
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 3 do |items|
            items.each do |item|
              assert_select item, "link", :count => 1 do |link|
                match = assert_match(/^#{changeset_url changeset}#c(\d+)$/, link.text)
                comment_id = match[1].to_i
                assert_operator comment_id, "<", last_comment_id if last_comment_id != -1
                last_comment_id = comment_id
              end
            end
          end
        end
      end
    end

    ##
    # test comments feed
    def test_feed_bad_limit
      get feeds_changeset_comments_path(:format => "rss", :limit => 0)
      assert_response :bad_request

      get feeds_changeset_comments_path(:format => "rss", :limit => 100001)
      assert_response :bad_request
    end
  end
end
