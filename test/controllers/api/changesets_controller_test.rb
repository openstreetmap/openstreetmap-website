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
      assert_routing(
        { :path => "/api/0.6/changeset/1/upload", :method => :post },
        { :controller => "api/changesets", :action => "upload", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/subscribe", :method => :post },
        { :controller => "api/changesets", :action => "subscribe", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/subscribe.json", :method => :post },
        { :controller => "api/changesets", :action => "subscribe", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/unsubscribe", :method => :post },
        { :controller => "api/changesets", :action => "unsubscribe", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/unsubscribe.json", :method => :post },
        { :controller => "api/changesets", :action => "unsubscribe", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/changeset/1/close", :method => :put },
        { :controller => "api/changesets", :action => "close", :id => "1" }
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
      changeset2 = create(:changeset, :min_lat => (5 * GeoRecord::SCALE).round, :min_lon => (5 * GeoRecord::SCALE).round, :max_lat => (15 * GeoRecord::SCALE).round, :max_lon => (15 * GeoRecord::SCALE).round)
      changeset3 = create(:changeset, :min_lat => (4.5 * GeoRecord::SCALE).round, :min_lon => (4.5 * GeoRecord::SCALE).round, :max_lat => (5 * GeoRecord::SCALE).round, :max_lon => (5 * GeoRecord::SCALE).round)

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
      auth_header = bearer_authorization_header create(:user, :data_public => false)
      # Create the first user's changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_require_public_data

      auth_header = bearer_authorization_header
      # Create the first user's changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header

      assert_response :success, "Creation of changeset did not return success status"
      newid = @response.body.to_i

      # check end time, should be an hour ahead of creation time
      cs = Changeset.find(newid)
      duration = cs.closed_at - cs.created_at
      # the difference can either be a rational, or a floating point number
      # of seconds, depending on the code path taken :-(
      if duration.instance_of?(Rational)
        assert_equal Rational(1, 24), duration, "initial idle timeout should be an hour (#{cs.created_at} -> #{cs.closed_at})"
      else
        # must be number of seconds...
        assert_equal 3600, duration.round, "initial idle timeout should be an hour (#{cs.created_at} -> #{cs.closed_at})"
      end

      # checks if uploader was subscribed
      assert_equal 1, cs.subscribers.length
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
      # test bbox attribute
      changeset = create(:changeset, :min_lat => (-5 * GeoRecord::SCALE).round, :min_lon => (5 * GeoRecord::SCALE).round,
                                     :max_lat => (15 * GeoRecord::SCALE).round, :max_lon => (12 * GeoRecord::SCALE).round)

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

    ##
    # test that the user who opened a change can close it
    def test_close
      private_user = create(:user, :data_public => false)
      private_changeset = create(:changeset, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)

      ## Try without authentication
      put changeset_close_path(changeset)
      assert_response :unauthorized

      ## Try using the non-public user
      auth_header = bearer_authorization_header private_user
      put changeset_close_path(private_changeset), :headers => auth_header
      assert_require_public_data

      ## The try with the public user
      auth_header = bearer_authorization_header user

      cs_id = changeset.id
      put changeset_close_path(cs_id), :headers => auth_header
      assert_response :success

      # test that it really is closed now
      cs = Changeset.find(changeset.id)
      assert_not(cs.open?,
                 "changeset should be closed now (#{cs.closed_at} > #{Time.now.utc}.")
    end

    ##
    # test that a different user can't close another user's changeset
    def test_close_invalid
      user = create(:user)
      changeset = create(:changeset)

      auth_header = bearer_authorization_header user

      put changeset_close_path(changeset), :headers => auth_header
      assert_response :conflict
      assert_equal "The user doesn't own that changeset", @response.body
    end

    ##
    # test that you can't close using another method
    def test_close_method_invalid
      user = create(:user)
      changeset = create(:changeset, :user => user)

      auth_header = bearer_authorization_header user

      get changeset_close_path(changeset), :headers => auth_header
      assert_response :not_found
      assert_template "rescues/routing_error"

      post changeset_close_path(changeset), :headers => auth_header
      assert_response :not_found
      assert_template "rescues/routing_error"
    end

    ##
    # check that you can't close a changeset that isn't found
    def test_close_not_found
      cs_ids = [0, -132, "123"]

      # First try to do it with no auth
      cs_ids.each do |id|
        put changeset_close_path(id)
        assert_response :unauthorized, "Shouldn't be able close the non-existant changeset #{id}, when not authorized"
      rescue ActionController::UrlGenerationError => e
        assert_match(/No route matches/, e.to_s)
      end

      # Now try with auth
      auth_header = bearer_authorization_header
      cs_ids.each do |id|
        put changeset_close_path(id), :headers => auth_header
        assert_response :not_found, "The changeset #{id} doesn't exist, so can't be closed"
      rescue ActionController::UrlGenerationError => e
        assert_match(/No route matches/, e.to_s)
      end
    end

    ##
    # upload something simple, but valid and check that it can
    # be read back ok
    # Also try without auth and another user.
    def test_upload_simple_valid
      private_user = create(:user, :data_public => false)
      private_changeset = create(:changeset, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)

      node = create(:node)
      way = create(:way)
      relation = create(:relation)
      other_relation = create(:relation)
      # create some tags, since we test that they are removed later
      create(:node_tag, :node => node)
      create(:way_tag, :way => way)
      create(:relation_tag, :relation => relation)

      ## Try with no auth
      changeset_id = changeset.id

      # simple diff to change a node, way and relation by removing
      # their tags
      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
          <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
           <nd ref='#{node.id}'/>
          </way>
         </modify>
         <modify>
          <relation id='#{relation.id}' changeset='#{changeset_id}' version='1'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{other_relation.id}'/>
          </relation>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff
      assert_response :unauthorized,
                      "shouldn't be able to upload a simple valid diff to changeset: #{@response.body}"

      ## Now try with a private user
      auth_header = bearer_authorization_header private_user
      changeset_id = private_changeset.id

      # simple diff to change a node, way and relation by removing
      # their tags
      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
          <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
           <nd ref='#{node.id}'/>
          </way>
         </modify>
         <modify>
          <relation id='#{relation.id}' changeset='#{changeset_id}' version='1'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{other_relation.id}'/>
          </relation>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(private_changeset), :params => diff, :headers => auth_header
      assert_response :forbidden,
                      "can't upload a simple valid diff to changeset: #{@response.body}"

      ## Now try with the public user
      auth_header = bearer_authorization_header user
      changeset_id = changeset.id

      # simple diff to change a node, way and relation by removing
      # their tags
      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset_id}' version='1'/>
          <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
           <nd ref='#{node.id}'/>
          </way>
         </modify>
         <modify>
          <relation id='#{relation.id}' changeset='#{changeset_id}' version='1'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{other_relation.id}'/>
          </relation>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a simple valid diff to changeset: #{@response.body}"

      # check that the changes made it into the database
      assert_equal 0, Node.find(node.id).tags.size, "node #{node.id} should now have no tags"
      assert_equal 0, Way.find(way.id).tags.size, "way #{way.id} should now have no tags"
      assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
    end

    ##
    # upload something which creates new objects using placeholders
    def test_upload_create_valid
      user = create(:user)
      changeset = create(:changeset, :user => user)
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)
      relation = create(:relation)

      auth_header = bearer_authorization_header user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
          <way id='-1' changeset='#{changeset.id}'>
           <nd ref='#{node.id}'/>
          </way>
         </create>
         <create>
          <relation id='-1' changeset='#{changeset.id}'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{relation.id}'/>
          </relation>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a simple valid creation to changeset: #{@response.body}"

      # check the returned payload
      new_node_id, new_way_id, new_rel_id = nil
      assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
        # inspect the response to find out what the new element IDs are
        # check the old IDs are all present and negative one
        # check the versions are present and equal one
        assert_dom "> node", 1 do |(node_el)|
          new_node_id = node_el["new_id"].to_i
          assert_dom "> @old_id", "-1"
          assert_dom "> @new_version", "1"
        end
        assert_dom "> way", 1 do |(way_el)|
          new_way_id = way_el["new_id"].to_i
          assert_dom "> @old_id", "-1"
          assert_dom "> @new_version", "1"
        end
        assert_dom "> relation", 1 do |(rel_el)|
          new_rel_id = rel_el["new_id"].to_i
          assert_dom "> @old_id", "-1"
          assert_dom "> @new_version", "1"
        end
      end

      # check that the changes made it into the database
      assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
      assert_equal 0, Way.find(new_way_id).tags.size, "new way should have no tags"
      assert_equal 0, Relation.find(new_rel_id).tags.size, "new relation should have no tags"
    end

    ##
    # test a complex delete where we delete elements which rely on eachother
    # in the same transaction.
    def test_upload_delete
      changeset = create(:changeset)
      super_relation = create(:relation)
      used_relation = create(:relation)
      used_way = create(:way)
      used_node = create(:node)
      create(:relation_member, :relation => super_relation, :member => used_relation)
      create(:relation_member, :relation => super_relation, :member => used_way)
      create(:relation_member, :relation => super_relation, :member => used_node)

      auth_header = bearer_authorization_header changeset.user

      diff = XML::Document.new
      diff.root = XML::Node.new "osmChange"
      delete = XML::Node.new "delete"
      diff.root << delete
      delete << xml_node_for_relation(super_relation)
      delete << xml_node_for_relation(used_relation)
      delete << xml_node_for_way(used_way)
      delete << xml_node_for_node(used_node)

      # update the changeset to one that this user owns
      %w[node way relation].each do |type|
        delete.find("//osmChange/delete/#{type}").each do |n|
          n["changeset"] = changeset.id.to_s
        end
      end

      # upload it
      post changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header
      assert_response :success,
                      "can't upload a deletion diff to changeset: #{@response.body}"

      # check the response is well-formed
      assert_select "diffResult>node", 1
      assert_select "diffResult>way", 1
      assert_select "diffResult>relation", 2

      # check that everything was deleted
      assert_not Node.find(used_node.id).visible
      assert_not Way.find(used_way.id).visible
      assert_not Relation.find(super_relation.id).visible
      assert_not Relation.find(used_relation.id).visible
    end

    ##
    # test uploading a delete with no lat/lon, as they are optional in
    # the osmChange spec.
    def test_upload_nolatlon_delete
      node = create(:node)
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user
      diff = "<osmChange><delete><node id='#{node.id}' version='#{node.version}' changeset='#{changeset.id}'/></delete></osmChange>"

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a deletion diff to changeset: #{@response.body}"

      # check the response is well-formed
      assert_select "diffResult>node", 1

      # check that everything was deleted
      assert_not Node.find(node.id).visible
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

    def test_upload_large_changeset
      user = create(:user)
      auth_header = bearer_authorization_header user

      # create an old changeset to ensure we have the maximum rate limit
      create(:changeset, :user => user, :created_at => Time.now.utc - 28.days)

      # create a changeset
      post api_changesets_path, :params => "<osm><changeset/></osm>", :headers => auth_header
      assert_response :success, "Should be able to create a changeset: #{@response.body}"
      changeset_id = @response.body.to_i

      # upload some widely-spaced nodes, spiralling positive and negative
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='-20' lat='-10' changeset='#{changeset_id}'/>
          <node id='-10' lon='20'  lat='10' changeset='#{changeset_id}'/>
          <node id='-2' lon='-40' lat='-20' changeset='#{changeset_id}'/>
          <node id='-11' lon='40'  lat='20' changeset='#{changeset_id}'/>
          <node id='-3' lon='-60' lat='-30' changeset='#{changeset_id}'/>
          <node id='-12' lon='60'  lat='30' changeset='#{changeset_id}'/>
          <node id='-4' lon='-80' lat='-40' changeset='#{changeset_id}'/>
          <node id='-13' lon='80'  lat='40' changeset='#{changeset_id}'/>
          <node id='-5' lon='-100' lat='-50' changeset='#{changeset_id}'/>
          <node id='-14' lon='100'  lat='50' changeset='#{changeset_id}'/>
          <node id='-6' lon='-120' lat='-60' changeset='#{changeset_id}'/>
          <node id='-15' lon='120'  lat='60' changeset='#{changeset_id}'/>
          <node id='-7' lon='-140' lat='-70' changeset='#{changeset_id}'/>
          <node id='-16' lon='140'  lat='70' changeset='#{changeset_id}'/>
          <node id='-8' lon='-160' lat='-80' changeset='#{changeset_id}'/>
          <node id='-17' lon='160'  lat='80' changeset='#{changeset_id}'/>
          <node id='-9' lon='-179.9' lat='-89.9' changeset='#{changeset_id}'/>
          <node id='-18' lon='179.9'  lat='89.9' changeset='#{changeset_id}'/>
         </create>
        </osmChange>
      CHANGESET

      # upload it, which used to cause an error like "PGError: ERROR:
      # integer out of range" (bug #2152). but shouldn't any more.
      post changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a spatially-large diff to changeset: #{@response.body}"

      # check that the changeset bbox is within bounds
      cs = Changeset.find(changeset_id)
      assert_operator cs.min_lon, :>=, -180 * GeoRecord::SCALE, "Minimum longitude (#{cs.min_lon / GeoRecord::SCALE}) should be >= -180 to be valid."
      assert_operator cs.max_lon, :<=, 180 * GeoRecord::SCALE, "Maximum longitude (#{cs.max_lon / GeoRecord::SCALE}) should be <= 180 to be valid."
      assert_operator cs.min_lat, :>=, -90 * GeoRecord::SCALE, "Minimum latitude (#{cs.min_lat / GeoRecord::SCALE}) should be >= -90 to be valid."
      assert_operator cs.max_lat, :<=, 90 * GeoRecord::SCALE, "Maximum latitude (#{cs.max_lat / GeoRecord::SCALE}) should be <= 90 to be valid."
    end

    ##
    # test that deleting stuff in a transaction doesn't bypass the checks
    # to ensure that used elements are not deleted.
    def test_upload_delete_invalid
      changeset = create(:changeset)
      relation = create(:relation)
      other_relation = create(:relation)
      used_way = create(:way)
      used_node = create(:node)
      create(:relation_member, :relation => relation, :member => used_way)
      create(:relation_member, :relation => relation, :member => used_node)

      auth_header = bearer_authorization_header changeset.user

      diff = XML::Document.new
      diff.root = XML::Node.new "osmChange"
      delete = XML::Node.new "delete"
      diff.root << delete
      delete << xml_node_for_relation(other_relation)
      delete << xml_node_for_way(used_way)
      delete << xml_node_for_node(used_node)

      # update the changeset to one that this user owns
      %w[node way relation].each do |type|
        delete.find("//osmChange/delete/#{type}").each do |n|
          n["changeset"] = changeset.id.to_s
        end
      end

      # upload it
      post changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header
      assert_response :precondition_failed,
                      "shouldn't be able to upload a invalid deletion diff: #{@response.body}"
      assert_equal "Precondition failed: Way #{used_way.id} is still used by relations #{relation.id}.", @response.body

      # check that nothing was, in fact, deleted
      assert Node.find(used_node.id).visible
      assert Way.find(used_way.id).visible
      assert Relation.find(relation.id).visible
      assert Relation.find(other_relation.id).visible
    end

    ##
    # test that a conditional delete of an in use object works.
    def test_upload_delete_if_unused
      changeset = create(:changeset)
      super_relation = create(:relation)
      used_relation = create(:relation)
      used_way = create(:way)
      used_node = create(:node)
      create(:relation_member, :relation => super_relation, :member => used_relation)
      create(:relation_member, :relation => super_relation, :member => used_way)
      create(:relation_member, :relation => super_relation, :member => used_node)

      auth_header = bearer_authorization_header changeset.user

      diff = XML::Document.new
      diff.root = XML::Node.new "osmChange"
      delete = XML::Node.new "delete"
      diff.root << delete
      delete["if-unused"] = ""
      delete << xml_node_for_relation(used_relation)
      delete << xml_node_for_way(used_way)
      delete << xml_node_for_node(used_node)

      # update the changeset to one that this user owns
      %w[node way relation].each do |type|
        delete.find("//osmChange/delete/#{type}").each do |n|
          n["changeset"] = changeset.id.to_s
        end
      end

      # upload it
      post changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header
      assert_response :success,
                      "can't do a conditional delete of in use objects: #{@response.body}"

      # check the returned payload
      assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
        # check the old IDs are all present and what we expect
        # check the new IDs are all present and unchanged
        # check the new versions are all present and unchanged
        assert_dom "> node", 1 do
          assert_dom "> @old_id", used_node.id.to_s
          assert_dom "> @new_id", used_node.id.to_s
          assert_dom "> @new_version", used_node.version.to_s
        end
        assert_dom "> way", 1 do
          assert_dom "> @old_id", used_way.id.to_s
          assert_dom "> @new_id", used_way.id.to_s
          assert_dom "> @new_version", used_way.version.to_s
        end
        assert_dom "> relation", 1 do
          assert_dom "> @old_id", used_relation.id.to_s
          assert_dom "> @new_id", used_relation.id.to_s
          assert_dom "> @new_version", used_relation.version.to_s
        end
      end

      # check that nothing was, in fact, deleted
      assert Node.find(used_node.id).visible
      assert Way.find(used_way.id).visible
      assert Relation.find(used_relation.id).visible
    end

    ##
    # upload an element with a really long tag value
    def test_upload_invalid_too_long_tag
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
           <tag k='foo' v='#{'x' * 256}'/>
          </node>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to upload too long a tag to changeset: #{@response.body}"
    end

    ##
    # upload something which creates new objects and inserts them into
    # existing containers using placeholders.
    def test_upload_complex
      way = create(:way)
      node = create(:node)
      relation = create(:relation)
      create(:way_node, :way => way, :node => node)

      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
         </create>
         <modify>
          <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
           <nd ref='-1'/>
           <nd ref='#{node.id}'/>
          </way>
          <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='-1'/>
           <member type='relation' role='some' ref='#{relation.id}'/>
          </relation>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a complex diff to changeset: #{@response.body}"

      # check the returned payload
      new_node_id = nil
      assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
        assert_dom "> node", 1 do |(node_el)|
          new_node_id = node_el["new_id"].to_i
        end
        assert_dom "> way", 1
        assert_dom "> relation", 1
      end

      # check that the changes made it into the database
      assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
      assert_equal [new_node_id, node.id], Way.find(way.id).nds, "way nodes should match"
      Relation.find(relation.id).members.each do |type, id, _role|
        assert_equal new_node_id, id, "relation should contain new node" if type == "node"
      end
    end

    ##
    # create a diff which references several changesets, which should cause
    # a rollback and none of the diff gets committed
    def test_upload_invalid_changesets
      changeset = create(:changeset)
      other_changeset = create(:changeset, :user => changeset.user)
      node = create(:node)
      way = create(:way)
      relation = create(:relation)
      other_relation = create(:relation)

      auth_header = bearer_authorization_header changeset.user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
          <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
           <nd ref='#{node.id}'/>
          </way>
         </modify>
         <modify>
          <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{other_relation.id}'/>
          </relation>
         </modify>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{other_changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :conflict,
                      "uploading a diff with multiple changesets should have failed"

      # check that objects are unmodified
      assert_nodes_are_equal(node, Node.find(node.id))
      assert_ways_are_equal(way, Way.find(way.id))
      assert_relations_are_equal(relation, Relation.find(relation.id))
    end

    ##
    # upload multiple versions of the same element in the same diff.
    def test_upload_multiple_valid
      node = create(:node)
      changeset = create(:changeset)
      auth_header = bearer_authorization_header changeset.user

      # change the location of a node multiple times, each time referencing
      # the last version. doesn't this depend on version numbers being
      # sequential?
      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0.0' lat='0.0' changeset='#{changeset.id}' version='1'/>
          <node id='#{node.id}' lon='0.1' lat='0.0' changeset='#{changeset.id}' version='2'/>
          <node id='#{node.id}' lon='0.1' lat='0.1' changeset='#{changeset.id}' version='3'/>
          <node id='#{node.id}' lon='0.1' lat='0.2' changeset='#{changeset.id}' version='4'/>
          <node id='#{node.id}' lon='0.2' lat='0.2' changeset='#{changeset.id}' version='5'/>
          <node id='#{node.id}' lon='0.3' lat='0.2' changeset='#{changeset.id}' version='6'/>
          <node id='#{node.id}' lon='0.3' lat='0.3' changeset='#{changeset.id}' version='7'/>
          <node id='#{node.id}' lon='0.9' lat='0.9' changeset='#{changeset.id}' version='8'/>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload multiple versions of an element in a diff: #{@response.body}"

      # check the response is well-formed. its counter-intuitive, but the
      # API will return multiple elements with the same ID and different
      # version numbers for each change we made.
      assert_select "diffResult>node", 8
    end

    ##
    # upload multiple versions of the same element in the same diff, but
    # keep the version numbers the same.
    def test_upload_multiple_duplicate
      node = create(:node)
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
          <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :conflict,
                      "shouldn't be able to upload the same element twice in a diff: #{@response.body}"
    end

    ##
    # try to upload some elements without specifying the version
    def test_upload_missing_version
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <modify>
         <node id='1' lon='1' lat='1' changeset='#{changeset.id}'/>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to upload an element without version: #{@response.body}"
    end

    ##
    # try to upload with commands other than create, modify, or delete
    def test_action_upload_invalid
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
          <ping>
           <node id='1' lon='1' lat='1' changeset='#{changeset.id}' />
          </ping>
        </osmChange>
      CHANGESET
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request, "Shouldn't be able to upload a diff with the action ping"
      assert_equal("Unknown action ping, choices are create, modify, delete", @response.body)
    end

    ##
    # upload a valid changeset which has a mixture of whitespace
    # to check a bug reported by ivansanchez (#1565).
    def test_upload_whitespace_valid
      changeset = create(:changeset)
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)
      relation = create(:relation)
      other_relation = create(:relation)
      create(:relation_tag, :relation => relation)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <modify><node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}'
          version='1'></node>
          <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='2'><tag k='k' v='v'/></node></modify>
         <modify>
         <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'><member
           type='way' role='some' ref='#{way.id}'/><member
            type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{other_relation.id}'/>
          </relation>
         </modify></osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a valid diff with whitespace variations to changeset: #{@response.body}"

      # check the response is well-formed
      assert_select "diffResult>node", 2
      assert_select "diffResult>relation", 1

      # check that the changes made it into the database
      assert_equal 1, Node.find(node.id).tags.size, "node #{node.id} should now have one tag"
      assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
    end

    ##
    # test that a placeholder can be reused within the same upload.
    def test_upload_reuse_placeholder_valid
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
           <tag k="foo" v="bar"/>
          </node>
         </create>
         <modify>
          <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
         </modify>
         <delete>
          <node id='-1' lon='2' lat='2' changeset='#{changeset.id}' version='2'/>
         </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a valid diff with re-used placeholders to changeset: #{@response.body}"

      # check the response is well-formed
      assert_select "diffResult>node", 3
      assert_select "diffResult>node[old_id='-1']", 3
    end

    ##
    # test what happens if a diff upload re-uses placeholder IDs in an
    # illegal way.
    def test_upload_placeholder_invalid
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
          <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
          <node id='-1' lon='2' lat='2' changeset='#{changeset.id}' version='2'/>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to re-use placeholder IDs"

      # placeholder_ids must be unique across all action blocks
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
         </create>
         <create>
          <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to re-use placeholder IDs"
    end

    def test_upload_process_order
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
        <create>
          <node id="-1" lat="1" lon="2" changeset="#{changeset.id}"/>
          <way id="-1" changeset="#{changeset.id}">
              <nd ref="-1"/>
              <nd ref="-2"/>
          </way>
          <node id="-2" lat="1" lon="2" changeset="#{changeset.id}"/>
        </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't refer elements behind it"
    end

    def test_upload_duplicate_delete
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
          <create>
            <node id="-1" lat="39" lon="116" changeset="#{changeset.id}" />
          </create>
          <delete>
            <node id="-1" version="1" changeset="#{changeset.id}" />
            <node id="-1" version="1" changeset="#{changeset.id}" />
          </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :gone,
                      "transaction should be cancelled by second deletion"

      diff = <<~CHANGESET
        <osmChange>
          <create>
            <node id="-1" lat="39" lon="116" changeset="#{changeset.id}" />
          </create>
          <delete if-unused="true">
            <node id="-1" version="1" changeset="#{changeset.id}" />
            <node id="-1" version="1" changeset="#{changeset.id}" />
          </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header

      assert_select "diffResult>node", 3
      assert_select "diffResult>node[old_id='-1']", 3
      assert_select "diffResult>node[new_version='1']", 1
      assert_select "diffResult>node[new_version='2']", 1
    end

    ##
    # test that uploading a way referencing invalid placeholders gives a
    # proper error, not a 500.
    def test_upload_placeholder_invalid_way
      changeset = create(:changeset)
      way = create(:way)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id="-1" lon="0.0" lat="0.0" changeset="#{changeset.id}" version="1"/>
          <node id="-2" lon="0.1" lat="0.1" changeset="#{changeset.id}" version="1"/>
          <node id="-3" lon="0.2" lat="0.2" changeset="#{changeset.id}" version="1"/>
          <way id="-1" changeset="#{changeset.id}" version="1">
           <nd ref="-1"/>
           <nd ref="-2"/>
           <nd ref="-3"/>
           <nd ref="-4"/>
          </way>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to use invalid placeholder IDs"
      assert_equal "Placeholder node not found for reference -4 in way -1", @response.body

      # the same again, but this time use an existing way
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id="-1" lon="0.0" lat="0.0" changeset="#{changeset.id}" version="1"/>
          <node id="-2" lon="0.1" lat="0.1" changeset="#{changeset.id}" version="1"/>
          <node id="-3" lon="0.2" lat="0.2" changeset="#{changeset.id}" version="1"/>
          <way id="#{way.id}" changeset="#{changeset.id}" version="1">
           <nd ref="-1"/>
           <nd ref="-2"/>
           <nd ref="-3"/>
           <nd ref="-4"/>
          </way>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to use invalid placeholder IDs"
      assert_equal "Placeholder node not found for reference -4 in way #{way.id}", @response.body
    end

    ##
    # test that uploading a relation referencing invalid placeholders gives a
    # proper error, not a 500.
    def test_upload_placeholder_invalid_relation
      changeset = create(:changeset)
      relation = create(:relation)

      auth_header = bearer_authorization_header changeset.user

      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id="-1" lon="0.0" lat="0.0" changeset="#{changeset.id}" version="1"/>
          <node id="-2" lon="0.1" lat="0.1" changeset="#{changeset.id}" version="1"/>
          <node id="-3" lon="0.2" lat="0.2" changeset="#{changeset.id}" version="1"/>
          <relation id="-1" changeset="#{changeset.id}" version="1">
           <member type="node" role="foo" ref="-1"/>
           <member type="node" role="foo" ref="-2"/>
           <member type="node" role="foo" ref="-3"/>
           <member type="node" role="foo" ref="-4"/>
          </relation>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to use invalid placeholder IDs"
      assert_equal "Placeholder Node not found for reference -4 in relation -1.", @response.body

      # the same again, but this time use an existing relation
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id="-1" lon="0.0" lat="0.0" changeset="#{changeset.id}" version="1"/>
          <node id="-2" lon="0.1" lat="0.1" changeset="#{changeset.id}" version="1"/>
          <node id="-3" lon="0.2" lat="0.2" changeset="#{changeset.id}" version="1"/>
          <relation id="#{relation.id}" changeset="#{changeset.id}" version="1">
           <member type="node" role="foo" ref="-1"/>
           <member type="node" role="foo" ref="-2"/>
           <member type="node" role="foo" ref="-3"/>
           <member type="way" role="bar" ref="-1"/>
          </relation>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :bad_request,
                      "shouldn't be able to use invalid placeholder IDs"
      assert_equal "Placeholder Way not found for reference -1 in relation #{relation.id}.", @response.body
    end

    ##
    # test what happens if a diff is uploaded containing only a node
    # move.
    def test_upload_node_move
      auth_header = bearer_authorization_header

      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success
      changeset_id = @response.body.to_i

      old_node = create(:node, :lat => 1, :lon => 1)

      diff = XML::Document.new
      diff.root = XML::Node.new "osmChange"
      modify = XML::Node.new "modify"
      xml_old_node = xml_node_for_node(old_node)
      xml_old_node["lat"] = 2.0.to_s
      xml_old_node["lon"] = 2.0.to_s
      xml_old_node["changeset"] = changeset_id.to_s
      modify << xml_old_node
      diff.root << modify

      # upload it
      post changeset_upload_path(changeset_id), :params => diff.to_s, :headers => auth_header
      assert_response :success,
                      "diff should have uploaded OK"

      # check the bbox
      changeset = Changeset.find(changeset_id)
      assert_equal 1 * GeoRecord::SCALE, changeset.min_lon, "min_lon should be 1 degree"
      assert_equal 2 * GeoRecord::SCALE, changeset.max_lon, "max_lon should be 2 degrees"
      assert_equal 1 * GeoRecord::SCALE, changeset.min_lat, "min_lat should be 1 degree"
      assert_equal 2 * GeoRecord::SCALE, changeset.max_lat, "max_lat should be 2 degrees"
    end

    ##
    # test what happens if a diff is uploaded adding a node to a way.
    def test_upload_way_extend
      auth_header = bearer_authorization_header

      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success
      changeset_id = @response.body.to_i

      old_way = create(:way)
      create(:way_node, :way => old_way, :node => create(:node, :lat => 0.1, :lon => 0.1))

      diff = XML::Document.new
      diff.root = XML::Node.new "osmChange"
      modify = XML::Node.new "modify"
      xml_old_way = xml_node_for_way(old_way)
      nd_ref = XML::Node.new "nd"
      nd_ref["ref"] = create(:node, :lat => 0.3, :lon => 0.3).id.to_s
      xml_old_way << nd_ref
      xml_old_way["changeset"] = changeset_id.to_s
      modify << xml_old_way
      diff.root << modify

      # upload it
      post changeset_upload_path(changeset_id), :params => diff.to_s, :headers => auth_header
      assert_response :success,
                      "diff should have uploaded OK"

      # check the bbox
      changeset = Changeset.find(changeset_id)
      assert_equal 0.1 * GeoRecord::SCALE, changeset.min_lon, "min_lon should be 0.1 degree"
      assert_equal 0.3 * GeoRecord::SCALE, changeset.max_lon, "max_lon should be 0.3 degrees"
      assert_equal 0.1 * GeoRecord::SCALE, changeset.min_lat, "min_lat should be 0.1 degree"
      assert_equal 0.3 * GeoRecord::SCALE, changeset.max_lat, "max_lat should be 0.3 degrees"
    end

    ##
    # test for more issues in #1568
    def test_upload_empty_invalid
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      ["<osmChange/>",
       "<osmChange></osmChange>",
       "<osmChange><modify/></osmChange>",
       "<osmChange><modify></modify></osmChange>"].each do |diff|
        # upload it
        post changeset_upload_path(changeset), :params => diff, :headers => auth_header
        assert_response(:success, "should be able to upload " \
                                  "empty changeset: " + diff)
      end
    end

    ##
    # test that the X-Error-Format header works to request XML errors
    def test_upload_xml_errors
      changeset = create(:changeset)
      node = create(:node)
      create(:relation_member, :member => node)

      auth_header = bearer_authorization_header changeset.user

      # try and delete a node that is in use
      diff = XML::Document.new
      diff.root = XML::Node.new "osmChange"
      delete = XML::Node.new "delete"
      diff.root << delete
      delete << xml_node_for_node(node)

      # upload it
      error_header = error_format_header "xml"
      post changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header.merge(error_header)
      assert_response :success,
                      "failed to return error in XML format"

      # check the returned payload
      assert_select "osmError[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
      assert_select "osmError>status", 1
      assert_select "osmError>message", 1
    end

    def test_upload_not_found
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      # modify node
      diff = <<~CHANGESET
        <osmChange>
        <modify>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :not_found, "Node should not be found"

      # modify way
      diff = <<~CHANGESET
        <osmChange>
        <modify>
          <way id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :not_found, "Way should not be found"

      # modify relation
      diff = <<~CHANGESET
        <osmChange>
        <modify>
          <relation id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :not_found, "Relation should not be found"

      # delete node
      diff = <<~CHANGESET
        <osmChange>
        <delete>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :not_found, "Node should not be deleted"

      # delete way
      diff = <<~CHANGESET
        <osmChange>
        <delete>
          <way id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :not_found, "Way should not be deleted"

      # delete relation
      diff = <<~CHANGESET
        <osmChange>
        <delete>
          <relation id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :not_found, "Relation should not be deleted"
    end

    def test_upload_relation_placeholder_not_fix
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      # modify node
      diff = <<~CHANGESET
        <osmChange version='0.6'>
          <create>
            <relation id='-2' version='0' changeset='#{changeset.id}'>
              <member type='relation' role='' ref='-4' />
              <tag k='type' v='route' />
              <tag k='name' v='AtoB' />
            </relation>
            <relation id='-3' version='0' changeset='#{changeset.id}'>
              <tag k='type' v='route' />
              <tag k='name' v='BtoA' />
            </relation>
            <relation id='-4' version='0' changeset='#{changeset.id}'>
              <member type='relation' role='' ref='-2' />
              <member type='relation' role='' ref='-3' />
              <tag k='type' v='route_master' />
              <tag k='name' v='master' />
            </relation>
          </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header
      assert_response :bad_request, "shouldn't be able to use reference -4 in relation -2: #{@response.body}"
      assert_equal "Placeholder Relation not found for reference -4 in relation -2.", @response.body
    end

    def test_upload_multiple_delete_block
      changeset = create(:changeset)

      auth_header = bearer_authorization_header changeset.user

      node = create(:node)
      way = create(:way)
      create(:way_node, :way => way, :node => node)
      alone_node = create(:node)

      # modify node
      diff = <<~CHANGESET
        <osmChange version='0.6'>
          <delete version="0.6">
            <node id="#{node.id}" version="#{node.version}" changeset="#{changeset.id}"/>
          </delete>
          <delete version="0.6" if-unused="true">
            <node id="#{alone_node.id}" version="#{alone_node.version}" changeset="#{changeset.id}"/>
          </delete>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header
      assert_response :precondition_failed,
                      "shouldn't be able to upload a invalid deletion diff: #{@response.body}"
      assert_equal "Precondition failed: Node #{node.id} is still used by ways #{way.id}.", @response.body
    end

    ##
    # test initial rate limit
    def test_upload_initial_rate_limit
      # create a user
      user = create(:user)

      # create some objects to use
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)
      relation = create(:relation)

      # create a changeset that puts us near the initial rate limit
      changeset = create(:changeset, :user => user,
                                     :created_at => Time.now.utc - 5.minutes,
                                     :num_changes => Settings.initial_changes_per_hour - 2)

      # create authentication header
      auth_header = bearer_authorization_header user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
          <way id='-1' changeset='#{changeset.id}'>
           <nd ref='#{node.id}'/>
          </way>
         </create>
         <create>
          <relation id='-1' changeset='#{changeset.id}'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{relation.id}'/>
          </relation>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :too_many_requests, "upload did not hit rate limit"
    end

    ##
    # test maximum rate limit
    def test_upload_maximum_rate_limit
      # create a user
      user = create(:user)

      # create some objects to use
      node = create(:node)
      way = create(:way_with_nodes, :nodes_count => 2)
      relation = create(:relation)

      # create a changeset to establish our initial edit time
      changeset = create(:changeset, :user => user,
                                     :created_at => Time.now.utc - 28.days)

      # create changeset to put us near the maximum rate limit
      total_changes = Settings.max_changes_per_hour - 2
      while total_changes.positive?
        changes = [total_changes, Changeset::MAX_ELEMENTS].min
        changeset = create(:changeset, :user => user,
                                       :created_at => Time.now.utc - 5.minutes,
                                       :num_changes => changes)
        total_changes -= changes
      end

      # create authentication header
      auth_header = bearer_authorization_header user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
          <way id='-1' changeset='#{changeset.id}'>
           <nd ref='#{node.id}'/>
          </way>
         </create>
         <create>
          <relation id='-1' changeset='#{changeset.id}'>
           <member type='way' role='some' ref='#{way.id}'/>
           <member type='node' role='some' ref='#{node.id}'/>
           <member type='relation' role='some' ref='#{relation.id}'/>
          </relation>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :too_many_requests, "upload did not hit rate limit"
    end

    ##
    # test initial size limit
    def test_upload_initial_size_limit
      # create a user
      user = create(:user)

      # create a changeset that puts us near the initial size limit
      changeset = create(:changeset, :user => user,
                                     :min_lat => (-0.5 * GeoRecord::SCALE).round, :min_lon => (0.5 * GeoRecord::SCALE).round,
                                     :max_lat => (0.5 * GeoRecord::SCALE).round, :max_lon => (2.5 * GeoRecord::SCALE).round)

      # create authentication header
      auth_header = bearer_authorization_header user

      # simple diff to create a node
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='0.9' lat='2.9' changeset='#{changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :payload_too_large, "upload did not hit size limit"
    end

    ##
    # test size limit after one week
    def test_upload_week_size_limit
      # create a user
      user = create(:user)

      # create a changeset to establish our initial edit time
      create(:changeset, :user => user, :created_at => Time.now.utc - 7.days)

      # create a changeset that puts us near the initial size limit
      changeset = create(:changeset, :user => user,
                                     :min_lat => (-0.5 * GeoRecord::SCALE).round, :min_lon => (0.5 * GeoRecord::SCALE).round,
                                     :max_lat => (0.5 * GeoRecord::SCALE).round, :max_lon => (2.5 * GeoRecord::SCALE).round)

      # create authentication header
      auth_header = bearer_authorization_header user

      # simple diff to create a node way and relation using placeholders
      diff = <<~CHANGESET
        <osmChange>
         <create>
          <node id='-1' lon='35' lat='35' changeset='#{changeset.id}'>
           <tag k='foo' v='bar'/>
           <tag k='baz' v='bat'/>
          </node>
         </create>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset), :params => diff, :headers => auth_header
      assert_response :payload_too_large, "upload did not hit size limit"
    end

    ##
    # when we make some simple changes we get the same changes back from the
    # diff download.
    def test_diff_download_simple
      node = create(:node)

      ## First try with a non-public user, which should get a forbidden
      auth_header = bearer_authorization_header create(:user, :data_public => false)

      # create a temporary changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :forbidden

      ## Now try with a normal user
      auth_header = bearer_authorization_header

      # create a temporary changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success
      changeset_id = @response.body.to_i

      # add a diff to it
      diff = <<~CHANGESET
        <osmChange>
         <modify>
          <node id='#{node.id}' lon='0.0' lat='0.0' changeset='#{changeset_id}' version='1'/>
          <node id='#{node.id}' lon='0.1' lat='0.0' changeset='#{changeset_id}' version='2'/>
          <node id='#{node.id}' lon='0.1' lat='0.1' changeset='#{changeset_id}' version='3'/>
          <node id='#{node.id}' lon='0.1' lat='0.2' changeset='#{changeset_id}' version='4'/>
          <node id='#{node.id}' lon='0.2' lat='0.2' changeset='#{changeset_id}' version='5'/>
          <node id='#{node.id}' lon='0.3' lat='0.2' changeset='#{changeset_id}' version='6'/>
          <node id='#{node.id}' lon='0.3' lat='0.3' changeset='#{changeset_id}' version='7'/>
          <node id='#{node.id}' lon='0.9' lat='0.9' changeset='#{changeset_id}' version='8'/>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload multiple versions of an element in a diff: #{@response.body}"

      get api_changeset_download_path(changeset_id)
      assert_response :success

      assert_select "osmChange", 1
      assert_select "osmChange>modify", 8
      assert_select "osmChange>modify>node", 8
    end

    ##
    # culled this from josm to ensure that nothing in the way that josm
    # is formatting the request is causing it to fail.
    #
    # NOTE: the error turned out to be something else completely!
    def test_josm_upload
      auth_header = bearer_authorization_header

      # create a temporary changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success
      changeset_id = @response.body.to_i

      diff = <<~OSMFILE
        <osmChange version="0.6" generator="JOSM">
        <create version="0.6" generator="JOSM">
          <node id='-1' visible='true' changeset='#{changeset_id}' lat='51.49619982187321' lon='-0.18722061869438314' />
          <node id='-2' visible='true' changeset='#{changeset_id}' lat='51.496359883909605' lon='-0.18653093576241928' />
          <node id='-3' visible='true' changeset='#{changeset_id}' lat='51.49598132358285' lon='-0.18719613290981638' />
          <node id='-4' visible='true' changeset='#{changeset_id}' lat='51.4961591711078' lon='-0.18629015888084607' />
          <node id='-5' visible='true' changeset='#{changeset_id}' lat='51.49582126021711' lon='-0.18708186591517145' />
          <node id='-6' visible='true' changeset='#{changeset_id}' lat='51.49591018437858' lon='-0.1861432441734455' />
          <node id='-7' visible='true' changeset='#{changeset_id}' lat='51.49560784152179' lon='-0.18694719410005425' />
          <node id='-8' visible='true' changeset='#{changeset_id}' lat='51.49567389979617' lon='-0.1860289771788006' />
          <node id='-9' visible='true' changeset='#{changeset_id}' lat='51.49543761398892' lon='-0.186820684213126' />
          <way id='-10' action='modify' visible='true' changeset='#{changeset_id}'>
            <nd ref='-1' />
            <nd ref='-2' />
            <nd ref='-3' />
            <nd ref='-4' />
            <nd ref='-5' />
            <nd ref='-6' />
            <nd ref='-7' />
            <nd ref='-8' />
            <nd ref='-9' />
            <tag k='highway' v='residential' />
            <tag k='name' v='Foobar Street' />
          </way>
        </create>
        </osmChange>
      OSMFILE

      # upload it
      post changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload a diff from JOSM: #{@response.body}"

      get api_changeset_download_path(changeset_id)
      assert_response :success

      assert_select "osmChange", 1
      assert_select "osmChange>create>node", 9
      assert_select "osmChange>create>way", 1
      assert_select "osmChange>create>way>nd", 9
      assert_select "osmChange>create>way>tag", 2
    end

    ##
    # when we make some complex changes we get the same changes back from the
    # diff download.
    def test_diff_download_complex
      node = create(:node)
      node2 = create(:node)
      way = create(:way)
      auth_header = bearer_authorization_header

      # create a temporary changeset
      xml = "<osm><changeset>" \
            "<tag k='created_by' v='osm test suite checking changesets'/>" \
            "</changeset></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success
      changeset_id = @response.body.to_i

      # add a diff to it
      diff = <<~CHANGESET
        <osmChange>
         <delete>
          <node id='#{node.id}' lon='0.0' lat='0.0' changeset='#{changeset_id}' version='1'/>
         </delete>
         <create>
          <node id='-1' lon='0.9' lat='0.9' changeset='#{changeset_id}' version='0'/>
          <node id='-2' lon='0.8' lat='0.9' changeset='#{changeset_id}' version='0'/>
          <node id='-3' lon='0.7' lat='0.9' changeset='#{changeset_id}' version='0'/>
         </create>
         <modify>
          <node id='#{node2.id}' lon='2.0' lat='1.5' changeset='#{changeset_id}' version='1'/>
          <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
           <nd ref='#{node2.id}'/>
           <nd ref='-1'/>
           <nd ref='-2'/>
           <nd ref='-3'/>
          </way>
         </modify>
        </osmChange>
      CHANGESET

      # upload it
      post changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
      assert_response :success,
                      "can't upload multiple versions of an element in a diff: #{@response.body}"

      get api_changeset_download_path(changeset_id)
      assert_response :success

      assert_select "osmChange", 1
      assert_select "osmChange>create", 3
      assert_select "osmChange>delete", 1
      assert_select "osmChange>modify", 2
      assert_select "osmChange>create>node", 3
      assert_select "osmChange>delete>node", 1
      assert_select "osmChange>modify>node", 1
      assert_select "osmChange>modify>way", 1
    end

    ##
    # check that the bounding box of a changeset gets updated correctly
    # FIXME: This should really be moded to a integration test due to the with_controller
    def test_changeset_bbox
      way = create(:way)
      create(:way_node, :way => way, :node => create(:node, :lat => 0.3, :lon => 0.3))

      auth_header = bearer_authorization_header

      # create a new changeset
      xml = "<osm><changeset/></osm>"
      post api_changesets_path, :params => xml, :headers => auth_header
      assert_response :success, "Creating of changeset failed."
      changeset_id = @response.body.to_i

      # add a single node to it
      with_controller(NodesController.new) do
        xml = "<osm><node lon='0.1' lat='0.2' changeset='#{changeset_id}'/></osm>"
        post api_nodes_path, :params => xml, :headers => auth_header
        assert_response :success, "Couldn't create node."
      end

      # get the bounding box back from the changeset
      get api_changeset_path(changeset_id)
      assert_response :success, "Couldn't read back changeset."
      assert_select "osm>changeset[min_lon='0.1000000']", 1
      assert_select "osm>changeset[max_lon='0.1000000']", 1
      assert_select "osm>changeset[min_lat='0.2000000']", 1
      assert_select "osm>changeset[max_lat='0.2000000']", 1

      # add another node to it
      with_controller(NodesController.new) do
        xml = "<osm><node lon='0.2' lat='0.1' changeset='#{changeset_id}'/></osm>"
        post api_nodes_path, :params => xml, :headers => auth_header
        assert_response :success, "Couldn't create second node."
      end

      # get the bounding box back from the changeset
      get api_changeset_path(changeset_id)
      assert_response :success, "Couldn't read back changeset for the second time."
      assert_select "osm>changeset[min_lon='0.1000000']", 1
      assert_select "osm>changeset[max_lon='0.2000000']", 1
      assert_select "osm>changeset[min_lat='0.1000000']", 1
      assert_select "osm>changeset[max_lat='0.2000000']", 1

      # add (delete) a way to it, which contains a point at (3,3)
      with_controller(WaysController.new) do
        xml = update_changeset(xml_for_way(way), changeset_id)
        delete api_way_path(way), :params => xml.to_s, :headers => auth_header
        assert_response :success, "Couldn't delete a way."
      end

      # get the bounding box back from the changeset
      get api_changeset_path(changeset_id)
      assert_response :success, "Couldn't read back changeset for the third time."
      assert_select "osm>changeset[min_lon='0.1000000']", 1
      assert_select "osm>changeset[max_lon='0.3000000']", 1
      assert_select "osm>changeset[min_lat='0.1000000']", 1
      assert_select "osm>changeset[max_lat='0.3000000']", 1
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
      cs_id = @response.body.to_i

      # start the counter just short of where the changeset should finish.
      offset = 10
      # alter the database to set the counter on the changeset directly,
      # otherwise it takes about 6 minutes to fill all of them.
      changeset = Changeset.find(cs_id)
      changeset.num_changes = Changeset::MAX_ELEMENTS - offset
      changeset.save!

      with_controller(NodesController.new) do
        # create a new node
        xml = "<osm><node changeset='#{cs_id}' lat='0.0' lon='0.0'/></osm>"
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

      changeset = Changeset.find(cs_id)
      assert_equal Changeset::MAX_ELEMENTS + 1, changeset.num_changes

      # check that the changeset is now closed as well
      assert_not(changeset.open?,
                 "changeset should have been auto-closed by exceeding " \
                 "element limit.")
    end

    ##
    # test subscribe success
    def test_subscribe_success
      auth_header = bearer_authorization_header
      changeset = create(:changeset, :closed)

      assert_difference "changeset.subscribers.count", 1 do
        post api_changeset_subscribe_path(changeset), :headers => auth_header
      end
      assert_response :success

      # not closed changeset
      changeset = create(:changeset)
      assert_difference "changeset.subscribers.count", 1 do
        post api_changeset_subscribe_path(changeset), :headers => auth_header
      end
      assert_response :success
    end

    ##
    # test subscribe fail
    def test_subscribe_fail
      user = create(:user)

      # unauthorized
      changeset = create(:changeset, :closed)
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_subscribe_path(changeset)
      end
      assert_response :unauthorized

      auth_header = bearer_authorization_header user

      # bad changeset id
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_subscribe_path(999111), :headers => auth_header
      end
      assert_response :not_found

      # trying to subscribe when already subscribed
      changeset = create(:changeset, :closed)
      changeset.subscribers.push(user)
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_subscribe_path(changeset), :headers => auth_header
      end
      assert_response :conflict
    end

    ##
    # test unsubscribe success
    def test_unsubscribe_success
      user = create(:user)
      auth_header = bearer_authorization_header user
      changeset = create(:changeset, :closed)
      changeset.subscribers.push(user)

      assert_difference "changeset.subscribers.count", -1 do
        post api_changeset_unsubscribe_path(changeset), :headers => auth_header
      end
      assert_response :success

      # not closed changeset
      changeset = create(:changeset)
      changeset.subscribers.push(user)

      assert_difference "changeset.subscribers.count", -1 do
        post api_changeset_unsubscribe_path(changeset), :headers => auth_header
      end
      assert_response :success
    end

    ##
    # test unsubscribe fail
    def test_unsubscribe_fail
      # unauthorized
      changeset = create(:changeset, :closed)
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_unsubscribe_path(changeset)
      end
      assert_response :unauthorized

      auth_header = bearer_authorization_header

      # bad changeset id
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_unsubscribe_path(999111), :headers => auth_header
      end
      assert_response :not_found

      # trying to unsubscribe when not subscribed
      changeset = create(:changeset, :closed)
      assert_no_difference "changeset.subscribers.count" do
        post api_changeset_unsubscribe_path(changeset), :headers => auth_header
      end
      assert_response :not_found
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
    # update the changeset_id of a way element
    def update_changeset(xml, changeset_id)
      xml_attr_rewrite(xml, "changeset", changeset_id)
    end

    ##
    # update an attribute in a way element
    def xml_attr_rewrite(xml, name, value)
      xml.find("//osm/way").first[name] = value.to_s
      xml
    end

    ##
    # build XML for changesets
    def create_changeset_xml(user: nil, id: nil)
      root = XML::Document.new
      root.root = XML::Node.new "osm"
      cs = XML::Node.new "changeset"
      if user
        cs["user"] = user.display_name
        cs["uid"] = user.id.to_s
      end
      cs["id"] = id.to_s if id
      root.root << cs
      root
    end
  end
end
