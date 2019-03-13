require "test_helper"

module Api
  class ChangesControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/changes", :method => :get },
        { :controller => "api/changes", :action => "index" }
      )
    end

    # MySQL and Postgres require that the C based functions are installed for
    # this test to work. More information is available from:
    # http://wiki.openstreetmap.org/wiki/Rails#Installing_the_quadtile_functions
    # or by looking at the readme in db/README
    def test_changes_simple
      # create a selection of nodes
      (1..5).each do |n|
        create(:node, :timestamp => Time.utc(2007, 1, 1, 0, 0, 0), :lat => n, :lon => n)
      end
      # deleted nodes should also be counted
      create(:node, :deleted, :timestamp => Time.utc(2007, 1, 1, 0, 0, 0), :lat => 6, :lon => 6)
      # nodes in the same tile won't change the total
      create(:node, :timestamp => Time.utc(2007, 1, 1, 0, 0, 0), :lat => 6, :lon => 6)
      # nodes with a different timestamp should be ignored
      create(:node, :timestamp => Time.utc(2008, 1, 1, 0, 0, 0), :lat => 7, :lon => 7)

      travel_to Time.utc(2010, 4, 3, 10, 55, 0) do
        get :index
        assert_response :success
        now = Time.now.getutc
        hourago = now - 1.hour
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "changes[starttime='#{hourago.xmlschema}'][endtime='#{now.xmlschema}']", :count => 1 do
            assert_select "tile", :count => 0
          end
        end
      end

      travel_to Time.utc(2007, 1, 1, 0, 30, 0) do
        get :index
        assert_response :success
        # print @response.body
        # As we have loaded the fixtures, we can assume that there are some
        # changes at the time we have frozen at
        now = Time.now.getutc
        hourago = now - 1.hour
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "changes[starttime='#{hourago.xmlschema}'][endtime='#{now.xmlschema}']", :count => 1 do
            assert_select "tile", :count => 6
          end
        end
      end
    end

    def test_changes_zoom_invalid
      zoom_to_test = %w[p -1 0 17 one two]
      zoom_to_test.each do |zoom|
        get :index, :params => { :zoom => zoom }
        assert_response :bad_request
        assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours"
      end
    end

    def test_changes_zoom_valid
      1.upto(16) do |zoom|
        get :index, :params => { :zoom => zoom }
        assert_response :success
        # NOTE: there was a test here for the timing, but it was too sensitive to be a good test
        # and it was annoying.
        assert_select "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", :count => 1 do
          assert_select "changes", :count => 1
        end
      end
    end

    def test_changes_hours_invalid
      invalid = %w[-21 335 -1 0 25 26 100 one two three ping pong :]
      invalid.each do |hour|
        get :index, :params => { :hours => hour }
        assert_response :bad_request, "Problem with the hour: #{hour}"
        assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours", "Problem with the hour: #{hour}."
      end
    end

    def test_changes_hours_valid
      1.upto(24) do |hour|
        get :index, :params => { :hours => hour }
        assert_response :success
      end
    end

    def test_changes_start_end_invalid
      get :index, :params => { :start => "2010-04-03 10:55:00", :end => "2010-04-03 09:55:00" }
      assert_response :bad_request
      assert_equal @response.body, "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours"
    end

    def test_changes_start_end_valid
      get :index, :params => { :start => "2010-04-03 09:55:00", :end => "2010-04-03 10:55:00" }
      assert_response :success
    end
  end
end
