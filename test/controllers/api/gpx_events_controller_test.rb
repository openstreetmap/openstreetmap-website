# frozen_string_literal: true

require "test_helper"

module Api
  class GpxEventsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/gpx/changes", :method => :get },
        { :controller => "api/gpx_events", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/gpx/changes.json", :method => :get },
        { :controller => "api/gpx_events", :action => "index", :format => "json" }
      )
    end

    def test_index
      event1 = create(:gpx_event, :action => "added")
      event2 = create(:gpx_event, :action => "removed")

      get api_gpx_events_path
      assert_response :success
      assert_equal "application/xml", response.media_type

      assert_dom "osm > gpx_changes[last_id='#{event2.id}']", 1 do
        assert_dom "> change", 2
        assert_dom "> change:nth-child(1)[id='#{event1.id}'][gpx_id='#{event1.gpx_id}'][action='added'][timestamp='#{event1.created_at.xmlschema}']"
        assert_dom "> change:nth-child(2)[id='#{event2.id}'][gpx_id='#{event2.gpx_id}'][action='removed']"
      end
    end

    def test_index_json
      event1 = create(:gpx_event, :action => "added")
      event2 = create(:gpx_event, :action => "removed")

      get api_gpx_events_path(:format => "json")
      assert_response :success
      assert_equal "application/json", response.media_type

      js = ActiveSupport::JSON.decode(@response.body)
      assert_equal event2.id, js["last_id"]
      assert_equal 2, js["changes"].count
      assert_equal({ "id" => event1.id, "gpx_id" => event1.gpx_id, "action" => "added", "timestamp" => event1.created_at.xmlschema }, js["changes"][0])
      assert_equal({ "id" => event2.id, "gpx_id" => event2.gpx_id, "action" => "removed", "timestamp" => event2.created_at.xmlschema }, js["changes"][1])
    end

    def test_index_without_events
      get api_gpx_events_path
      assert_response :success

      assert_dom "osm > gpx_changes[last_id='0']", 1 do
        assert_dom "> change", 0
      end
    end

    def test_index_since
      event1 = create(:gpx_event)
      event2 = create(:gpx_event)
      event3 = create(:gpx_event)

      get api_gpx_events_path(:since => event1.id)
      assert_response :success

      assert_dom "osm > gpx_changes[last_id='#{event3.id}'] > change", 2
      assert_dom "change[id='#{event1.id}']", 0
      assert_dom "change[id='#{event2.id}']", 1
      assert_dom "change[id='#{event3.id}']", 1
    end

    def test_index_since_the_last_event
      event = create(:gpx_event)

      get api_gpx_events_path(:since => event.id)
      assert_response :success

      assert_dom "osm > gpx_changes[last_id='#{event.id}']", 1 do
        assert_dom "> change", 0
      end
    end

    def test_index_since_invalid
      get api_gpx_events_path(:since => "abc")
      assert_response :bad_request

      get api_gpx_events_path(:since => "-1")
      assert_response :bad_request
    end

    def test_index_from
      event1 = create(:gpx_event, :created_at => Time.utc(2026, 1, 1))
      event2 = create(:gpx_event, :created_at => Time.utc(2026, 2, 1))
      event3 = create(:gpx_event, :created_at => Time.utc(2026, 3, 1))

      get api_gpx_events_path(:from => "2026-02-01T00:00:00Z")
      assert_response :success

      assert_dom "change", 2
      assert_dom "change[id='#{event1.id}']", 0
      assert_dom "change[id='#{event2.id}']", 1
      assert_dom "change[id='#{event3.id}']", 1
    end

    def test_index_from_after_the_last_event
      event = create(:gpx_event, :created_at => Time.utc(2026, 1, 1))

      get api_gpx_events_path(:from => "2026-02-01T00:00:00Z")
      assert_response :success

      assert_dom "osm > gpx_changes[last_id='#{event.id}']", 1 do
        assert_dom "> change", 0
      end
    end

    def test_index_from_and_since
      event1 = create(:gpx_event, :created_at => Time.utc(2026, 1, 1))
      event2 = create(:gpx_event, :created_at => Time.utc(2026, 2, 1))
      event3 = create(:gpx_event, :created_at => Time.utc(2026, 3, 1))

      get api_gpx_events_path(:from => "2026-02-01T00:00:00Z", :since => event2.id)
      assert_response :success

      assert_dom "change", 1
      assert_dom "change[id='#{event1.id}']", 0
      assert_dom "change[id='#{event3.id}']", 1
    end

    def test_index_from_invalid
      get api_gpx_events_path(:from => "not a date")
      assert_response :bad_request
    end

    def test_index_limit
      event1 = create(:gpx_event)
      event2 = create(:gpx_event)
      event3 = create(:gpx_event)

      get api_gpx_events_path(:limit => 2)
      assert_response :success

      assert_dom "osm > gpx_changes[last_id='#{event3.id}'] > change", 2
      assert_dom "change[id='#{event1.id}']", 1
      assert_dom "change[id='#{event2.id}']", 1
    end

    def test_index_default_limit
      create_list(:gpx_event, 3)

      with_settings(:default_gpx_event_query_limit => 2) do
        get api_gpx_events_path
        assert_response :success
        assert_dom "change", 2
      end
    end

    def test_index_limit_invalid
      get api_gpx_events_path(:limit => 0)
      assert_response :bad_request

      get api_gpx_events_path(:limit => Settings.max_gpx_event_query_limit + 1)
      assert_response :bad_request
    end

    def test_index_disabled
      with_settings(:traces_disabled => true) do
        get api_gpx_events_path
        assert_response :not_found
      end
    end
  end
end
