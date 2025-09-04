# frozen_string_literal: true

require "test_helper"

module Api
  class ChangesetsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/changesets", :method => :get },
        { :controller => "api/changesets", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/changesets.json", :method => :get },
        { :controller => "api/changesets", :action => "index", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changesets", :method => :post },
        { :controller => "api/changesets", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1", :method => :get },
        { :controller => "api/changesets", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1.json", :method => :get },
        { :controller => "api/changesets", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1", :method => :put },
        { :controller => "api/changesets", :action => "update", :id => "1" }
      )

      assert_recognizes(
        { :controller => "api/changesets", :action => "create" },
        { :path => "/api/0.6/changeset/create", :method => :put }
      )
    end

    ##
    # test the query functionality of changesets
    def test_index
      private_user = create(:user, :data_public => false)
      private_user_changeset = create(:changeset, :user => private_user)
      private_user_closed_changeset = create(:changeset, :closed, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      closed_changeset = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 1, 1, 0, 0, 0), :closed_at => Time.utc(2008, 1, 2, 0, 0, 0))
      changeset2 = create(:changeset, :bbox => [5, 5, 15, 15])
      changeset3 = create(:changeset, :bbox => [4.5, 4.5, 5, 5])

      get api_changesets_path(:bbox => "-10,-10, 10, 10")
      assert_response :success, "can't get changesets in bbox"
      assert_changesets_in_order [changeset3, changeset2]

      get api_changesets_path(:bbox => "4.5,4.5,4.6,4.6")
      assert_response :success, "can't get changesets in bbox"
      assert_changesets_in_order [changeset3]

      # not found when looking for changesets of non-existing users
      get api_changesets_path(:user => User.maximum(:id) + 1)
      assert_response :not_found
      assert_equal "text/plain", @response.media_type
      get api_changesets_path(:display_name => " ")
      assert_response :not_found
      assert_equal "text/plain", @response.media_type

      # can't get changesets of user 1 without authenticating
      get api_changesets_path(:user => private_user.id)
      assert_response :not_found, "shouldn't be able to get changesets by non-public user (ID)"
      get api_changesets_path(:display_name => private_user.display_name)
      assert_response :not_found, "shouldn't be able to get changesets by non-public user (name)"

      # but this should work
      auth_header = bearer_authorization_header private_user
      get api_changesets_path(:user => private_user.id), :headers => auth_header
      assert_response :success, "can't get changesets by user ID"
      assert_changesets_in_order [private_user_changeset, private_user_closed_changeset]

      get api_changesets_path(:display_name => private_user.display_name), :headers => auth_header
      assert_response :success, "can't get changesets by user name"
      assert_changesets_in_order [private_user_changeset, private_user_closed_changeset]

      # test json endpoint
      get api_changesets_path(:display_name => private_user.display_name), :headers => auth_header, :params => { :format => "json" }
      assert_response :success, "can't get changesets by user name"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_equal 2, js["changesets"].count

      # check that the correct error is given when we provide both UID and name
      get api_changesets_path(:user => private_user.id,
                              :display_name => private_user.display_name), :headers => auth_header
      assert_response :bad_request, "should be a bad request to have both ID and name specified"

      get api_changesets_path(:user => private_user.id, :open => true), :headers => auth_header
      assert_response :success, "can't get changesets by user and open"
      assert_changesets_in_order [private_user_changeset]

      get api_changesets_path(:time => "2007-12-31"), :headers => auth_header
      assert_response :success, "can't get changesets by time-since"
      assert_changesets_in_order [changeset3, changeset2, changeset, private_user_changeset, private_user_closed_changeset, closed_changeset]

      get api_changesets_path(:time => "2008-01-01T12:34Z"), :headers => auth_header
      assert_response :success, "can't get changesets by time-since with hour"
      assert_changesets_in_order [changeset3, changeset2, changeset, private_user_changeset, private_user_closed_changeset, closed_changeset]

      get api_changesets_path(:time => "2007-12-31T23:59Z,2008-01-02T00:01Z"), :headers => auth_header
      assert_response :success, "can't get changesets by time-range"
      assert_changesets_in_order [closed_changeset]

      get api_changesets_path(:open => "true"), :headers => auth_header
      assert_response :success, "can't get changesets by open-ness"
      assert_changesets_in_order [changeset3, changeset2, changeset, private_user_changeset]

      get api_changesets_path(:closed => "true"), :headers => auth_header
      assert_response :success, "can't get changesets by closed-ness"
      assert_changesets_in_order [private_user_closed_changeset, closed_changeset]

      get api_changesets_path(:closed => "true", :user => private_user.id), :headers => auth_header
      assert_response :success, "can't get changesets by closed-ness and user"
      assert_changesets_in_order [private_user_closed_changeset]

      get api_changesets_path(:closed => "true", :user => user.id), :headers => auth_header
      assert_response :success, "can't get changesets by closed-ness and user"
      assert_changesets_in_order [closed_changeset]

      get api_changesets_path(:changesets => "#{private_user_changeset.id},#{changeset.id},#{closed_changeset.id}"), :headers => auth_header
      assert_response :success, "can't get changesets by id (as comma-separated string)"
      assert_changesets_in_order [changeset, private_user_changeset, closed_changeset]

      get api_changesets_path(:changesets => ""), :headers => auth_header
      assert_response :bad_request, "should be a bad request since changesets is empty"
    end

    ##
    # test the query functionality of changesets with the limit parameter
    def test_index_limit
      user = create(:user)
      changeset1 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 1, 1, 0, 0, 0), :closed_at => Time.utc(2008, 1, 2, 0, 0, 0))
      changeset2 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 2, 1, 0, 0, 0), :closed_at => Time.utc(2008, 2, 2, 0, 0, 0))
      changeset3 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 3, 1, 0, 0, 0), :closed_at => Time.utc(2008, 3, 2, 0, 0, 0))
      changeset4 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 4, 1, 0, 0, 0), :closed_at => Time.utc(2008, 4, 2, 0, 0, 0))
      changeset5 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 5, 1, 0, 0, 0), :closed_at => Time.utc(2008, 5, 2, 0, 0, 0))

      get api_changesets_path
      assert_response :success
      assert_changesets_in_order [changeset5, changeset4, changeset3, changeset2, changeset1]

      get api_changesets_path(:limit => "3")
      assert_response :success
      assert_changesets_in_order [changeset5, changeset4, changeset3]

      get api_changesets_path(:limit => "0")
      assert_response :bad_request

      get api_changesets_path(:limit => Settings.max_changeset_query_limit)
      assert_response :success
      assert_changesets_in_order [changeset5, changeset4, changeset3, changeset2, changeset1]

      get api_changesets_path(:limit => Settings.max_changeset_query_limit + 1)
      assert_response :bad_request
    end

    ##
    # test the query functionality of sequential changesets with order and time parameters
    def test_index_order
      user = create(:user)
      changeset1 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 1, 1, 0, 0, 0), :closed_at => Time.utc(2008, 1, 2, 0, 0, 0))
      changeset2 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 2, 1, 0, 0, 0), :closed_at => Time.utc(2008, 2, 2, 0, 0, 0))
      changeset3 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 3, 1, 0, 0, 0), :closed_at => Time.utc(2008, 3, 2, 0, 0, 0))
      changeset4 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 4, 1, 0, 0, 0), :closed_at => Time.utc(2008, 4, 2, 0, 0, 0))
      changeset5 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 5, 1, 0, 0, 0), :closed_at => Time.utc(2008, 5, 2, 0, 0, 0))
      changeset6 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2008, 6, 1, 0, 0, 0), :closed_at => Time.utc(2008, 6, 2, 0, 0, 0))

      get api_changesets_path
      assert_response :success
      assert_changesets_in_order [changeset6, changeset5, changeset4, changeset3, changeset2, changeset1]

      get api_changesets_path(:order => "oldest")
      assert_response :success
      assert_changesets_in_order [changeset1, changeset2, changeset3, changeset4, changeset5, changeset6]

      [
        # lower time bound at the opening time of a changeset
        ["2008-02-01T00:00:00Z", "2008-05-15T00:00:00Z", [changeset5, changeset4, changeset3, changeset2], [changeset5, changeset4, changeset3, changeset2]],
        # lower time bound in the middle of a changeset
        ["2008-02-01T12:00:00Z", "2008-05-15T00:00:00Z", [changeset5, changeset4, changeset3, changeset2], [changeset5, changeset4, changeset3]],
        # lower time bound at the closing time of a changeset
        ["2008-02-02T00:00:00Z", "2008-05-15T00:00:00Z", [changeset5, changeset4, changeset3, changeset2], [changeset5, changeset4, changeset3]],
        # lower time bound after the closing time of a changeset
        ["2008-02-02T00:00:01Z", "2008-05-15T00:00:00Z", [changeset5, changeset4, changeset3], [changeset5, changeset4, changeset3]],
        # upper time bound in the middle of a changeset
        ["2007-09-09T12:00:00Z", "2008-04-01T12:00:00Z", [changeset4, changeset3, changeset2, changeset1], [changeset4, changeset3, changeset2, changeset1]],
        # empty range
        ["2009-02-02T00:00:01Z", "2018-05-15T00:00:00Z", [], []]
      ].each do |from, to, interval_changesets, point_changesets|
        get api_changesets_path(:time => "#{from},#{to}")
        assert_response :success
        assert_changesets_in_order interval_changesets

        get api_changesets_path(:from => from, :to => to)
        assert_response :success
        assert_changesets_in_order point_changesets

        get api_changesets_path(:from => from, :to => to, :order => "oldest")
        assert_response :success
        assert_changesets_in_order point_changesets.reverse
      end
    end

    ##
    # test the query functionality of overlapping changesets with order and time parameters
    def test_index_order_overlapping
      user = create(:user)
      changeset1 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2015, 6, 4, 17, 0, 0), :closed_at => Time.utc(2015, 6, 4, 17, 0, 0))
      changeset2 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2015, 6, 4, 16, 0, 0), :closed_at => Time.utc(2015, 6, 4, 18, 0, 0))
      changeset3 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2015, 6, 4, 14, 0, 0), :closed_at => Time.utc(2015, 6, 4, 20, 0, 0))
      changeset4 = create(:changeset, :closed, :user => user, :created_at => Time.utc(2015, 6, 3, 23, 0, 0), :closed_at => Time.utc(2015, 6, 4, 23, 0, 0))
      create(:changeset, :closed, :user => user, :created_at => Time.utc(2015, 6, 2, 23, 0, 0), :closed_at => Time.utc(2015, 6, 3, 23, 0, 0))

      get api_changesets_path(:time => "2015-06-04T00:00:00Z")
      assert_response :success
      assert_changesets_in_order [changeset1, changeset2, changeset3, changeset4]

      get api_changesets_path(:from => "2015-06-04T00:00:00Z")
      assert_response :success
      assert_changesets_in_order [changeset1, changeset2, changeset3]

      get api_changesets_path(:from => "2015-06-04T00:00:00Z", :order => "oldest")
      assert_response :success
      assert_changesets_in_order [changeset3, changeset2, changeset1]

      get api_changesets_path(:time => "2015-06-04T16:00:00Z,2015-06-04T17:30:00Z")
      assert_response :success
      assert_changesets_in_order [changeset1, changeset2, changeset3, changeset4]

      get api_changesets_path(:from => "2015-06-04T16:00:00Z", :to => "2015-06-04T17:30:00Z")
      assert_response :success
      assert_changesets_in_order [changeset1, changeset2]

      get api_changesets_path(:from => "2015-06-04T16:00:00Z", :to => "2015-06-04T17:30:00Z", :order => "oldest")
      assert_response :success
      assert_changesets_in_order [changeset2, changeset1]
    end

    ##
    # check that errors are returned if garbage is inserted
    # into query strings
    def test_index_invalid
      ["abracadabra!",
       "1,2,3,F",
       ";drop table users;"].each do |bbox|
        get api_changesets_path(:bbox => bbox)
        assert_response :bad_request, "'#{bbox}' isn't a bbox"
      end

      ["now()",
       "00-00-00",
       ";drop table users;",
       ",",
       "-,-"].each do |time|
        get api_changesets_path(:time => time)
        assert_response :bad_request, "'#{time}' isn't a valid time range"
      end

      ["me",
       "foobar",
       "-1",
       "0"].each do |uid|
        get api_changesets_path(:user => uid)
        assert_response :bad_request, "'#{uid}' isn't a valid user ID"
      end

      get api_changesets_path(:order => "oldest", :time => "2008-01-01T00:00Z,2018-01-01T00:00Z")
      assert_response :bad_request, "cannot use order=oldest with time"
    end

    # -----------------------
    # Test simple changeset creation
    # -----------------------

    def test_create
      user = create(:user)
      auth_header = bearer_authorization_header user
      # Create the first user's changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"

      assert_difference "Changeset.count", 1 do
        post api_changesets_path, :params => xml, :headers => auth_header
        assert_response :success, "Creation of changeset did not return success status"
      end
      newid = @response.body.to_i

      # check end time, should be an hour ahead of creation time
      changeset = Changeset.find(newid)
      duration = changeset.closed_at - changeset.created_at
      # the difference can either be a rational, or a floating point number
      # of seconds, depending on the code path taken :-(
      if duration.instance_of?(Rational)
        assert_equal Rational(1, 24), duration, "initial idle timeout should be an hour (#{changeset.created_at} -> #{changeset.closed_at})"
      else
        # must be number of seconds...
        assert_equal 3600, duration.round, "initial idle timeout should be an hour (#{changeset.created_at} -> #{changeset.closed_at})"
      end

      assert_equal [user], changeset.subscribers
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create_invalid
      auth_header = bearer_authorization_header create(:user, :data_public => false)
      xml = "<osm><changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_require_public_data

      ## Try the public user
      auth_header = bearer_authorization_header
      xml = "<osm><changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :bad_request, "creating a invalid changeset should fail"
    end

    def test_create_invalid_no_content
      ## First check with no auth
      post api_changesets_path
      assert_response :unauthorized, "shouldn't be able to create a changeset with no auth"

      ## Now try to with a non-public user
      auth_header = bearer_authorization_header create(:user, :data_public => false)
      post api_changesets_path, :headers => auth_header
      assert_require_public_data

      ## Try an inactive user
      auth_header = bearer_authorization_header create(:user, :pending)
      post api_changesets_path, :headers => auth_header
      assert_inactive_user

      ## Now try to use a normal user
      auth_header = bearer_authorization_header
      post api_changesets_path, :headers => auth_header
      assert_response :bad_request, "creating a changeset with no content should fail"
    end

    def test_create_wrong_method
      auth_header = bearer_authorization_header

      put api_changesets_path, :headers => auth_header
      assert_response :not_found
      assert_template "rescues/routing_error"
    end

    def test_create_legacy_path
      auth_header = bearer_authorization_header
      xml = "<osm><changeset></changeset></osm>"

      assert_difference "Changeset.count", 1 do
        put "/api/0.6/changeset/create", :params => xml, :headers => auth_header
      end

      assert_response :success, "Creation of changeset did not return success status"
      assert_equal Changeset.last.id, @response.body.to_i
    end

    ##
    # check that the changeset can be shown and returns the correct
    # document structure.
    def test_show
      changeset = create(:changeset)

      get api_changeset_path(changeset)
      assert_response :success, "cannot get first changeset"

      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_single_changeset changeset do
        assert_dom "> discussion", 0
      end

      get api_changeset_path(changeset, :include_discussion => true)
      assert_response :success, "cannot get first changeset with comments"

      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_single_changeset changeset do
        assert_dom "> discussion", 1
        assert_dom "> discussion > comment", 0
      end
    end

    def test_show_comments
      # all comments visible
      changeset = create(:changeset, :closed)
      comment1, comment2, comment3 = create_list(:changeset_comment, 3, :changeset_id => changeset.id)

      get api_changeset_path(changeset, :include_discussion => true)
      assert_response :success, "cannot get closed changeset with comments"

      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
        assert_single_changeset changeset do
          assert_dom "> discussion", 1 do
            assert_dom "> comment", 3 do |dom_comments|
              assert_dom dom_comments[0], "> @id", comment1.id.to_s
              assert_dom dom_comments[0], "> @visible", "true"
              assert_dom dom_comments[1], "> @id", comment2.id.to_s
              assert_dom dom_comments[1], "> @visible", "true"
              assert_dom dom_comments[2], "> @id", comment3.id.to_s
              assert_dom dom_comments[2], "> @visible", "true"
            end
          end
        end
      end

      # one hidden comment not included because not asked for
      comment2.update(:visible => false)
      changeset.reload

      get api_changeset_path(changeset, :include_discussion => true)
      assert_response :success, "cannot get closed changeset with comments"

      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_single_changeset changeset do
        assert_dom "> discussion", 1 do
          assert_dom "> comment", 2 do |dom_comments|
            assert_dom dom_comments[0], "> @id", comment1.id.to_s
            assert_dom dom_comments[0], "> @visible", "true"
            assert_dom dom_comments[1], "> @id", comment3.id.to_s
            assert_dom dom_comments[1], "> @visible", "true"
          end
        end
      end

      # one hidden comment not included because no permissions
      get api_changeset_path(changeset, :include_discussion => true, :show_hidden_comments => true)
      assert_response :success, "cannot get closed changeset with comments"

      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_single_changeset changeset do
        assert_dom "> discussion", 1 do
          assert_dom "> comment", 2 do |dom_comments|
            assert_dom dom_comments[0], "> @id", comment1.id.to_s
            assert_dom dom_comments[0], "> @visible", "true"
            # maybe will show an empty comment element with visible=false in the future
            assert_dom dom_comments[1], "> @id", comment3.id.to_s
            assert_dom dom_comments[1], "> @visible", "true"
          end
        end
      end

      # one hidden comment shown to moderators
      moderator_user = create(:moderator_user)
      auth_header = bearer_authorization_header moderator_user
      get api_changeset_path(changeset, :include_discussion => true, :show_hidden_comments => true), :headers => auth_header
      assert_response :success, "cannot get closed changeset with comments"

      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_single_changeset changeset do
        assert_dom "> discussion", 1 do
          assert_dom "> comment", 3 do |dom_comments|
            assert_dom dom_comments[0], "> @id", comment1.id.to_s
            assert_dom dom_comments[0], "> @visible", "true"
            assert_dom dom_comments[1], "> @id", comment2.id.to_s
            assert_dom dom_comments[1], "> @visible", "false"
            assert_dom dom_comments[2], "> @id", comment3.id.to_s
            assert_dom dom_comments[2], "> @visible", "true"
          end
        end
      end
    end

    def test_show_tags
      changeset = create(:changeset, :closed)
      create(:changeset_tag, :changeset => changeset, :k => "created_by", :v => "JOSM/1.5 (18364)")
      create(:changeset_tag, :changeset => changeset, :k => "comment", :v => "changeset comment")

      get api_changeset_path(changeset)

      assert_response :success
      assert_dom "osm[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_single_changeset changeset do
        assert_dom "> tag", 2
        assert_dom "> tag[k='created_by'][v='JOSM/1.5 (18364)']", 1
        assert_dom "> tag[k='comment'][v='changeset comment']", 1
      end
    end

    def test_show_json
      changeset = create(:changeset)

      get api_changeset_path(changeset, :format => "json")
      assert_response :success, "cannot get first changeset"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js

      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_nil js["changeset"]["tags"]
      assert_nil js["changeset"]["comments"]
      assert_equal changeset.user.id, js["changeset"]["uid"]
      assert_equal changeset.user.display_name, js["changeset"]["user"]

      get api_changeset_path(changeset, :format => "json", :include_discussion => true)
      assert_response :success, "cannot get first changeset with comments"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_nil js["changeset"]["tags"]
      assert_nil js["changeset"]["min_lat"]
      assert_nil js["changeset"]["min_lon"]
      assert_nil js["changeset"]["max_lat"]
      assert_nil js["changeset"]["max_lon"]
      assert_equal 0, js["changeset"]["comments"].count
    end

    def test_show_comments_json
      # all comments visible
      changeset = create(:changeset, :closed)
      comment0, comment1, comment2 = create_list(:changeset_comment, 3, :changeset_id => changeset.id)

      get api_changeset_path(changeset, :format => "json", :include_discussion => true)
      assert_response :success, "cannot get closed changeset with comments"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_equal 3, js["changeset"]["comments"].count
      assert_equal comment0.id, js["changeset"]["comments"][0]["id"]
      assert js["changeset"]["comments"][0]["visible"]
      assert_equal comment1.id, js["changeset"]["comments"][1]["id"]
      assert js["changeset"]["comments"][1]["visible"]
      assert_equal comment2.id, js["changeset"]["comments"][2]["id"]
      assert js["changeset"]["comments"][2]["visible"]

      # one hidden comment not included because not asked for
      comment1.update(:visible => false)
      changeset.reload

      get api_changeset_path(changeset, :format => "json", :include_discussion => true)
      assert_response :success, "cannot get closed changeset with comments"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_equal 2, js["changeset"]["comments"].count
      assert_equal comment0.id, js["changeset"]["comments"][0]["id"]
      assert js["changeset"]["comments"][0]["visible"]
      assert_equal comment2.id, js["changeset"]["comments"][1]["id"]
      assert js["changeset"]["comments"][1]["visible"]

      # one hidden comment not included because no permissions
      get api_changeset_path(changeset, :format => "json", :include_discussion => true, :show_hidden_comments => true)
      assert_response :success, "cannot get closed changeset with comments"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_equal 2, js["changeset"]["comments"].count
      assert_equal comment0.id, js["changeset"]["comments"][0]["id"]
      assert js["changeset"]["comments"][0]["visible"]
      # maybe will show an empty comment element with visible=false in the future
      assert_equal comment2.id, js["changeset"]["comments"][1]["id"]
      assert js["changeset"]["comments"][1]["visible"]

      # one hidden comment shown to moderators
      moderator_user = create(:moderator_user)
      auth_header = bearer_authorization_header moderator_user
      get api_changeset_path(changeset, :format => "json", :include_discussion => true, :show_hidden_comments => true), :headers => auth_header
      assert_response :success, "cannot get closed changeset with comments"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_equal 3, js["changeset"]["comments"].count
      assert_equal comment0.id, js["changeset"]["comments"][0]["id"]
      assert js["changeset"]["comments"][0]["visible"]
      assert_equal comment1.id, js["changeset"]["comments"][1]["id"]
      assert_not js["changeset"]["comments"][1]["visible"]
      assert_equal comment2.id, js["changeset"]["comments"][2]["id"]
      assert js["changeset"]["comments"][2]["visible"]
    end

    def test_show_tags_json
      changeset = create(:changeset, :closed)
      create(:changeset_tag, :changeset => changeset, :k => "created_by", :v => "JOSM/1.5 (18364)")
      create(:changeset_tag, :changeset => changeset, :k => "comment", :v => "changeset comment")

      get api_changeset_path(changeset, :format => "json")

      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal Settings.api_version, js["version"]
      assert_equal Settings.generator, js["generator"]
      assert_single_changeset_json changeset, js
      assert_equal 2, js["changeset"]["tags"].count
      assert_equal "JOSM/1.5 (18364)", js["changeset"]["tags"]["created_by"]
      assert_equal "changeset comment", js["changeset"]["tags"]["comment"]
    end

    def test_show_bbox_json
      changeset = create(:changeset, :bbox => [5, -5, 12, 15])

      get api_changeset_path(changeset, :format => "json")
      assert_response :success, "cannot get first changeset"

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal(-5, js["changeset"]["min_lat"])
      assert_equal 5, js["changeset"]["min_lon"]
      assert_equal 15, js["changeset"]["max_lat"]
      assert_equal 12, js["changeset"]["max_lon"]
    end

    ##
    # check that a changeset that doesn't exist returns an appropriate message
    def test_show_not_found
      [0, -32, 233455644, "afg", "213"].each do |id|
        get api_changeset_path(id)
        assert_response :not_found, "should get a not found"
      rescue ActionController::UrlGenerationError => e
        assert_match(/No route matches/, e.to_s)
      end
    end

    def test_repeated_changeset_create
      3.times do
        auth_header = bearer_authorization_header

        # create a temporary changeset
        xml = "<osm><changeset>" \
              "<tag k='created_by' v='osm test suite checking changesets'/>" \
              "</changeset></osm>"
        assert_difference "Changeset.count", 1 do
          post api_changesets_path, :params => xml, :headers => auth_header
        end
        assert_response :success
      end
    end

    ##
    # check updating tags on a changeset
    def test_changeset_update
      private_user = create(:user, :data_public => false)
      private_changeset = create(:changeset, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)

      ## First try with a non-public user
      new_changeset = create_changeset_xml(:user => private_user)
      new_tag = XML::Node.new "tag"
      new_tag["k"] = "tagtesting"
      new_tag["v"] = "valuetesting"
      new_changeset.find("//osm/changeset").first << new_tag

      # try without any authorization
      put api_changeset_path(private_changeset), :params => new_changeset.to_s
      assert_response :unauthorized

      # try with the wrong authorization
      auth_header = bearer_authorization_header
      put api_changeset_path(private_changeset), :params => new_changeset.to_s, :headers => auth_header
      assert_response :conflict

      # now this should get an unauthorized
      auth_header = bearer_authorization_header private_user
      put api_changeset_path(private_changeset), :params => new_changeset.to_s, :headers => auth_header
      assert_require_public_data "user with their data non-public, shouldn't be able to edit their changeset"

      ## Now try with the public user
      new_changeset = create_changeset_xml(:id => 1)
      new_tag = XML::Node.new "tag"
      new_tag["k"] = "tagtesting"
      new_tag["v"] = "valuetesting"
      new_changeset.find("//osm/changeset").first << new_tag

      # try without any authorization
      put api_changeset_path(changeset), :params => new_changeset.to_s
      assert_response :unauthorized

      # try with the wrong authorization
      auth_header = bearer_authorization_header
      put api_changeset_path(changeset), :params => new_changeset.to_s, :headers => auth_header
      assert_response :conflict

      # now this should work...
      auth_header = bearer_authorization_header user
      put api_changeset_path(changeset), :params => new_changeset.to_s, :headers => auth_header
      assert_response :success

      assert_select "osm>changeset[id='#{changeset.id}']", 1
      assert_select "osm>changeset>tag", 1
      assert_select "osm>changeset>tag[k='tagtesting'][v='valuetesting']", 1
    end

    ##
    # check that a user different from the one who opened the changeset
    # can't modify it.
    def test_changeset_update_invalid
      auth_header = bearer_authorization_header

      changeset = create(:changeset)
      new_changeset = create_changeset_xml(:user => changeset.user, :id => changeset.id)
      new_tag = XML::Node.new "tag"
      new_tag["k"] = "testing"
      new_tag["v"] = "testing"
      new_changeset.find("//osm/changeset").first << new_tag

      put api_changeset_path(changeset), :params => new_changeset.to_s, :headers => auth_header
      assert_response :conflict
    end

    ##
    # check that a changeset can contain a certain max number of changes.
    ## FIXME should be changed to an integration test due to the with_controller
    def test_changeset_limits
      user = create(:user)
      auth_header = bearer_authorization_header user

      # create an old changeset to ensure we have the maximum rate limit
      create(:changeset, :user => user, :created_at => Time.now.utc - 28.days)

      # open a new changeset
      xml = "<osm><changeset/></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success, "can't create a new changeset"
      changeset_id = @response.body.to_i

      # start the counter just short of where the changeset should finish.
      offset = 10
      # alter the database to set the counter on the changeset directly,
      # otherwise it takes about 6 minutes to fill all of them.
      changeset = Changeset.find(changeset_id)
      changeset.num_changes = Changeset::MAX_ELEMENTS - offset
      changeset.save!

      with_controller(NodesController.new) do
        # create a new node
        xml = "<osm><node changeset='#{changeset_id}' lat='0.0' lon='0.0'/></osm>"
        post api_nodes_path, :params => xml, :headers => auth_header
        assert_response :success, "can't create a new node"
        node_id = @response.body.to_i

        get api_node_path(node_id)
        assert_response :success, "can't read back new node"
        node_doc = XML::Parser.string(@response.body).parse
        node_xml = node_doc.find("//osm/node").first

        # loop until we fill the changeset with nodes
        offset.times do |i|
          node_xml["lat"] = rand.to_s
          node_xml["lon"] = rand.to_s
          node_xml["version"] = (i + 1).to_s

          put api_node_path(node_id), :params => node_doc.to_s, :headers => auth_header
          assert_response :success, "attempt #{i} should have succeeded"
        end

        # trying again should fail
        node_xml["lat"] = rand.to_s
        node_xml["lon"] = rand.to_s
        node_xml["version"] = offset.to_s

        put api_node_path(node_id), :params => node_doc.to_s, :headers => auth_header
        assert_response :conflict, "final attempt should have failed"
      end

      changeset = Changeset.find(changeset_id)
      assert_equal Changeset::MAX_ELEMENTS + 1, changeset.num_changes

      # check that the changeset is now closed as well
      assert_not(changeset.open?,
                 "changeset should have been auto-closed by exceeding " \
                 "element limit.")
    end

    private

    ##
    # check that the output consists of one specific changeset
    def assert_single_changeset(changeset, &)
      assert_dom "> changeset", 1 do
        assert_dom "> @id", changeset.id.to_s
        assert_dom "> @created_at", changeset.created_at.xmlschema
        if changeset.open?
          assert_dom "> @open", "true"
          assert_dom "> @closed_at", 0
        else
          assert_dom "> @open", "false"
          assert_dom "> @closed_at", changeset.closed_at.xmlschema
        end
        assert_dom "> @comments_count", changeset.comments.length.to_s
        assert_dom "> @changes_count", changeset.num_changes.to_s
        yield if block_given?
      end
    end

    def assert_single_changeset_json(changeset, js)
      assert_equal changeset.id, js["changeset"]["id"]
      assert_equal changeset.created_at.xmlschema, js["changeset"]["created_at"]
      if changeset.open?
        assert js["changeset"]["open"]
        assert_nil js["changeset"]["closed_at"]
      else
        assert_not js["changeset"]["open"]
        assert_equal changeset.closed_at.xmlschema, js["changeset"]["closed_at"]
      end
      assert_equal changeset.comments.length, js["changeset"]["comments_count"]
      assert_equal changeset.num_changes, js["changeset"]["changes_count"]
    end

    ##
    # check that certain changesets exist in the output in the specified order
    def assert_changesets_in_order(changesets)
      assert_select "osm>changeset", changesets.size
      changesets.each_with_index do |changeset, index|
        assert_select "osm>changeset:nth-child(#{index + 1})[id='#{changeset.id}']", 1
      end
    end

    ##
    # build XML for changesets
    def create_changeset_xml(user: nil, id: nil)
      root = XML::Document.new
      root.root = XML::Node.new "osm"
      changeset = XML::Node.new "changeset"
      if user
        changeset["user"] = user.display_name
        changeset["uid"] = user.id.to_s
      end
      changeset["id"] = id.to_s if id
      root.root << changeset
      root
    end
  end
end
