require "test_helper"

module Api
  class NoteVersionsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/notes/1/history", :method => :get },
        { :controller => "api/note_versions", :action => "index", :note_id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1/history.json", :method => :get },
        { :controller => "api/note_versions", :action => "index", :note_id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1/2", :method => :get },
        { :controller => "api/note_versions", :action => "show", :note_id => "1", :version => "2" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1/2.json", :method => :get },
        { :controller => "api/note_versions", :action => "show", :note_id => "1", :version => "2", :format => "json" }
      )
    end

    ##
    # test retrieving specific version
    def test_retrieving_specific_version
      # Create closed note with 2 versions (opening and closing)
      note = create(:note_with_comments, :closed)

      # Gets note's version 1
      get api_note_version_path(note, 1, :format => "json")
      assert_response :success

      # Check response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["properties"]["version"]

      # Gets note's version 2
      get api_note_version_path(note, 2, :format => "json")
      assert_response :success

      # Check response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 2, js["properties"]["version"]
    end

    ##
    # test retrieving history
    def test_retrieving_history
      # Create closed note with 2 versions (opening and closing)
      note = create(:note_with_comments, :closed)

      # Gets note's history
      get api_note_versions_path(note, 1, :format => "json")
      assert_response :success

      # Check response
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 1, js["features"][0]["properties"]["version"]
      assert_equal 2, js["features"][1]["properties"]["version"]
    end
  end
end
