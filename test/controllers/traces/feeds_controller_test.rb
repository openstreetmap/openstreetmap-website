require "test_helper"

module Traces
  class FeedsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/traces/rss", :method => :get },
        { :controller => "traces/feeds", :action => "show", :format => :rss }
      )
      assert_routing(
        { :path => "/traces/tag/tagname/rss", :method => :get },
        { :controller => "traces/feeds", :action => "show", :tag => "tagname", :format => :rss }
      )
      assert_routing(
        { :path => "/user/username/traces/rss", :method => :get },
        { :controller => "traces/feeds", :action => "show", :display_name => "username", :format => :rss }
      )
      assert_routing(
        { :path => "/user/username/traces/tag/tagname/rss", :method => :get },
        { :controller => "traces/feeds", :action => "show", :display_name => "username", :tag => "tagname", :format => :rss }
      )
    end

    def test_show
      user = create(:user)
      # The fourth test below is surprisingly sensitive to timestamp ordering when the timestamps are equal.
      trace_a = create(:trace, :visibility => "public", :timestamp => 4.seconds.ago) do |trace|
        create(:tracetag, :trace => trace, :tag => "London")
      end
      trace_b = create(:trace, :visibility => "public", :timestamp => 3.seconds.ago) do |trace|
        create(:tracetag, :trace => trace, :tag => "Birmingham")
      end
      create(:trace, :visibility => "private", :user => user, :timestamp => 2.seconds.ago) do |trace|
        create(:tracetag, :trace => trace, :tag => "London")
      end
      create(:trace, :visibility => "private", :user => user, :timestamp => 1.second.ago) do |trace|
        create(:tracetag, :trace => trace, :tag => "Birmingham")
      end

      # First with the public feed
      get traces_feed_path
      check_trace_feed [trace_b, trace_a]

      # Restrict traces to those with a given tag
      get traces_feed_path(:tag => "London")
      check_trace_feed [trace_a]
    end

    def test_show_user
      user = create(:user)
      second_user = create(:user)
      create(:user)
      create(:trace)
      trace_b = create(:trace, :visibility => "public", :timestamp => 4.seconds.ago, :user => user)
      trace_c = create(:trace, :visibility => "public", :timestamp => 3.seconds.ago, :user => user) do |trace|
        create(:tracetag, :trace => trace, :tag => "London")
      end
      create(:trace, :visibility => "private")

      # Test a user with no traces
      get traces_feed_path(:display_name => second_user)
      check_trace_feed []

      # Test the user with the traces - should see only public ones
      get traces_feed_path(:display_name => user)
      check_trace_feed [trace_c, trace_b]

      # Should only see traces with the correct tag when a tag is specified
      get traces_feed_path(:display_name => user, :tag => "London")
      check_trace_feed [trace_c]

      # Should no traces if the user does not exist
      get traces_feed_path(:display_name => "UnknownUser")
      check_trace_feed []
    end

    private

    def check_trace_feed(traces)
      assert_response :success
      assert_template "traces/feeds/show"
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "title"
          assert_select "description"
          assert_select "link"
          assert_select "image"
          assert_select "item", :count => traces.length do |items|
            traces.zip(items).each do |trace, item|
              assert_select item, "title", trace.name
              assert_select item, "link", "http://www.example.com/user/#{ERB::Util.u(trace.user.display_name)}/traces/#{trace.id}"
              assert_select item, "guid", "http://www.example.com/user/#{ERB::Util.u(trace.user.display_name)}/traces/#{trace.id}"
              assert_select item, "description" do
                assert_dom_encoded do
                  assert_select "img[src='#{trace_icon_url trace.user, trace}']"
                end
              end
              # assert_select item, "dc:creator", trace.user.display_name
              assert_select item, "pubDate", trace.timestamp.rfc822
            end
          end
        end
      end
    end
  end
end
