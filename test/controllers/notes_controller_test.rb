require "test_helper"

class NotesControllerTest < ActionController::TestCase
  fixtures :users, :user_roles, :notes, :note_comments

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/notes", :method => :post },
      { :controller => "notes", :action => "create", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "xml" }
    )
    assert_recognizes(
      { :controller => "notes", :action => "show", :id => "1", :format => "xml" },
      { :path => "/api/0.6/notes/1.xml", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1.rss", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "rss" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1.json", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "json" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1.gpx", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "gpx" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1/comment", :method => :post },
      { :controller => "notes", :action => "comment", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1/close", :method => :post },
      { :controller => "notes", :action => "close", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1/reopen", :method => :post },
      { :controller => "notes", :action => "reopen", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1", :method => :delete },
      { :controller => "notes", :action => "destroy", :id => "1", :format => "xml" }
    )

    assert_routing(
      { :path => "/api/0.6/notes", :method => :get },
      { :controller => "notes", :action => "index", :format => "xml" }
    )
    assert_recognizes(
      { :controller => "notes", :action => "index", :format => "xml" },
      { :path => "/api/0.6/notes.xml", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/notes.rss", :method => :get },
      { :controller => "notes", :action => "index", :format => "rss" }
    )
    assert_routing(
      { :path => "/api/0.6/notes.json", :method => :get },
      { :controller => "notes", :action => "index", :format => "json" }
    )
    assert_routing(
      { :path => "/api/0.6/notes.gpx", :method => :get },
      { :controller => "notes", :action => "index", :format => "gpx" }
    )

    assert_routing(
      { :path => "/api/0.6/notes/search", :method => :get },
      { :controller => "notes", :action => "search", :format => "xml" }
    )
    assert_recognizes(
      { :controller => "notes", :action => "search", :format => "xml" },
      { :path => "/api/0.6/notes/search.xml", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/notes/search.rss", :method => :get },
      { :controller => "notes", :action => "search", :format => "rss" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/search.json", :method => :get },
      { :controller => "notes", :action => "search", :format => "json" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/search.gpx", :method => :get },
      { :controller => "notes", :action => "search", :format => "gpx" }
    )

    assert_routing(
      { :path => "/api/0.6/notes/feed", :method => :get },
      { :controller => "notes", :action => "feed", :format => "rss" }
    )

    assert_recognizes(
      { :controller => "notes", :action => "create" },
      { :path => "/api/0.6/notes/addPOIexec", :method => :post }
    )
    assert_recognizes(
      { :controller => "notes", :action => "close" },
      { :path => "/api/0.6/notes/closePOIexec", :method => :post }
    )
    assert_recognizes(
      { :controller => "notes", :action => "comment" },
      { :path => "/api/0.6/notes/editPOIexec", :method => :post }
    )
    assert_recognizes(
      { :controller => "notes", :action => "index", :format => "gpx" },
      { :path => "/api/0.6/notes/getGPX", :method => :get }
    )
    assert_recognizes(
      { :controller => "notes", :action => "feed", :format => "rss" },
      { :path => "/api/0.6/notes/getRSSfeed", :method => :get }
    )

    assert_routing(
      { :path => "/user/username/notes", :method => :get },
      { :controller => "notes", :action => "mine", :display_name => "username" }
    )
  end

  def test_create_success
    assert_difference "Note.count", 1 do
      assert_difference "NoteComment.count", 1 do
        post :create, :lat => -1.0, :lon => -1.0, :text => "This is a comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal "Point", js["geometry"]["type"]
    assert_equal [-1.0, -1.0], js["geometry"]["coordinates"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 1, js["properties"]["comments"].count
    assert_equal "opened", js["properties"]["comments"].last["action"]
    assert_equal "This is a comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]
    id = js["properties"]["id"]

    get :show, :id => id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal "Point", js["geometry"]["type"]
    assert_equal [-1.0, -1.0], js["geometry"]["coordinates"]
    assert_equal id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 1, js["properties"]["comments"].count
    assert_equal "opened", js["properties"]["comments"].last["action"]
    assert_equal "This is a comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]
  end

  def test_create_fail
    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lon => -1.0, :text => "This is a comment"
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -1.0, :text => "This is a comment"
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -1.0, :lon => -1.0
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -1.0, :lon => -1.0, :text => ""
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -100.0, :lon => -1.0, :text => "This is a comment"
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -1.0, :lon => -200.0, :text => "This is a comment"
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => "abc", :lon => -1.0, :text => "This is a comment"
      end
    end
    assert_response :bad_request

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -1.0, :lon => "abc", :text => "This is a comment"
      end
    end
    assert_response :bad_request
  end

  def test_comment_success
    assert_difference "NoteComment.count", 1 do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post :comment, :id => notes(:open_note_with_comment).id, :text => "This is an additional comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    get :show, :id => notes(:open_note_with_comment).id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    assert_difference "NoteComment.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 2 do
        post :comment, :id => notes(:note_with_comments_by_users).id, :text => "This is an additional comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:note_with_comments_by_users).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == "test@openstreetmap.org" }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] An anonymous user has commented on one of your notes", email.subject

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == "public@OpenStreetMap.org" }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] An anonymous user has commented on a note you are interested in", email.subject

    get :show, :id => notes(:note_with_comments_by_users).id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:note_with_comments_by_users).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    ActionMailer::Base.deliveries.clear

    basic_authorization(users(:public_user).email, "test")

    assert_difference "NoteComment.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 2 do
        post :comment, :id => notes(:note_with_comments_by_users).id, :text => "This is an additional comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:note_with_comments_by_users).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 4, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_equal "test2", js["properties"]["comments"].last["user"]

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == "test@openstreetmap.org" }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] test2 has commented on one of your notes", email.subject
    assert_equal "test@openstreetmap.org", email.to.first

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == "public@OpenStreetMap.org" }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] test2 has commented on a note you are interested in", email.subject

    get :show, :id => notes(:note_with_comments_by_users).id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:note_with_comments_by_users).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 4, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_equal "test2", js["properties"]["comments"].last["user"]

    ActionMailer::Base.deliveries.clear
  end

  def test_comment_fail
    assert_no_difference "NoteComment.count" do
      post :comment, :text => "This is an additional comment"
    end
    assert_response :bad_request

    assert_no_difference "NoteComment.count" do
      post :comment, :id => notes(:open_note_with_comment).id
    end
    assert_response :bad_request

    assert_no_difference "NoteComment.count" do
      post :comment, :id => notes(:open_note_with_comment).id, :text => ""
    end
    assert_response :bad_request

    assert_no_difference "NoteComment.count" do
      post :comment, :id => 12345, :text => "This is an additional comment"
    end
    assert_response :not_found

    assert_no_difference "NoteComment.count" do
      post :comment, :id => notes(:hidden_note_with_comment).id, :text => "This is an additional comment"
    end
    assert_response :gone

    assert_no_difference "NoteComment.count" do
      post :comment, :id => notes(:closed_note_with_comment).id, :text => "This is an additional comment"
    end
    assert_response :conflict
  end

  def test_close_success
    post :close, :id => notes(:open_note_with_comment).id, :text => "This is a close comment", :format => "json"
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, "test")

    post :close, :id => notes(:open_note_with_comment).id, :text => "This is a close comment", :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "closed", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "closed", js["properties"]["comments"].last["action"]
    assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
    assert_equal "test2", js["properties"]["comments"].last["user"]

    get :show, :id => notes(:open_note_with_comment).id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "closed", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "closed", js["properties"]["comments"].last["action"]
    assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
    assert_equal "test2", js["properties"]["comments"].last["user"]
  end

  def test_close_fail
    post :close
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, "test")

    post :close
    assert_response :bad_request

    post :close, :id => 12345
    assert_response :not_found

    post :close, :id => notes(:hidden_note_with_comment).id
    assert_response :gone

    post :close, :id => notes(:closed_note_with_comment).id
    assert_response :conflict
  end

  def test_reopen_success
    post :reopen, :id => notes(:closed_note_with_comment).id, :text => "This is a reopen comment", :format => "json"
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, "test")

    post :reopen, :id => notes(:closed_note_with_comment).id, :text => "This is a reopen comment", :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:closed_note_with_comment).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "reopened", js["properties"]["comments"].last["action"]
    assert_equal "This is a reopen comment", js["properties"]["comments"].last["text"]
    assert_equal "test2", js["properties"]["comments"].last["user"]

    get :show, :id => notes(:closed_note_with_comment).id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:closed_note_with_comment).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "reopened", js["properties"]["comments"].last["action"]
    assert_equal "This is a reopen comment", js["properties"]["comments"].last["text"]
    assert_equal "test2", js["properties"]["comments"].last["user"]
  end

  def test_reopen_fail
    post :reopen, :id => notes(:hidden_note_with_comment).id
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, "test")

    post :reopen, :id => 12345
    assert_response :not_found

    post :reopen, :id => notes(:hidden_note_with_comment).id
    assert_response :gone

    post :reopen, :id => notes(:open_note_with_comment).id
    assert_response :conflict
  end

  def test_show_success
    get :show, :id => notes(:open_note).id, :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note[lat='#{notes(:open_note).lat}'][lon='#{notes(:open_note).lon}']", :count => 1 do
        assert_select "id", notes(:open_note).id
        assert_select "url", note_url(notes(:open_note), :format => "xml")
        assert_select "comment_url", comment_note_url(notes(:open_note), :format => "xml")
        assert_select "close_url", close_note_url(notes(:open_note), :format => "xml")
        assert_select "date_created", notes(:open_note).created_at.to_s
        assert_select "status", notes(:open_note).status
        assert_select "comments", :count => 1 do
          assert_select "comment", :count => 1
        end
      end
    end

    get :show, :id => notes(:open_note).id, :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 1 do
          assert_select "link", browse_note_url(notes(:open_note))
          assert_select "guid", note_url(notes(:open_note))
          assert_select "pubDate", notes(:open_note).created_at.to_s(:rfc822)
          #          assert_select "geo:lat", notes(:open_note).lat.to_s
          #          assert_select "geo:long", notes(:open_note).lon
          #          assert_select "georss:point", "#{notes(:open_note).lon} #{notes(:open_note).lon}"
        end
      end
    end

    get :show, :id => notes(:open_note).id, :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal "Point", js["geometry"]["type"]
    assert_equal notes(:open_note).lat, js["geometry"]["coordinates"][0]
    assert_equal notes(:open_note).lon, js["geometry"]["coordinates"][1]
    assert_equal notes(:open_note).id, js["properties"]["id"]
    assert_equal note_url(notes(:open_note), :format => "json"), js["properties"]["url"]
    assert_equal comment_note_url(notes(:open_note), :format => "json"), js["properties"]["comment_url"]
    assert_equal close_note_url(notes(:open_note), :format => "json"), js["properties"]["close_url"]
    assert_equal notes(:open_note).created_at, js["properties"]["date_created"]
    assert_equal notes(:open_note).status, js["properties"]["status"]

    get :show, :id => notes(:open_note).id, :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt[lat='#{notes(:open_note).lat}'][lon='#{notes(:open_note).lon}']", :count => 1 do
        assert_select "extension", :count => 1 do
          assert_select "id", notes(:open_note).id
          assert_select "url", note_url(notes(:open_note), :format => "gpx")
          assert_select "comment_url", comment_note_url(notes(:open_note), :format => "gpx")
          assert_select "close_url", close_note_url(notes(:open_note), :format => "gpx")
        end
      end
    end
  end

  def test_show_hidden_comment
    get :show, :id => notes(:note_with_hidden_comment).id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:note_with_hidden_comment).id, js["properties"]["id"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "Valid comment for note 5", js["properties"]["comments"][0]["text"]
    assert_equal "Another valid comment for note 5", js["properties"]["comments"][1]["text"]
  end

  def test_show_fail
    get :show, :id => 12345
    assert_response :not_found

    get :show, :id => notes(:hidden_note_with_comment).id
    assert_response :gone
  end

  def test_destroy_success
    delete :destroy, :id => notes(:open_note_with_comment).id, :text => "This is a hide comment", :format => "json"
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, "test")

    delete :destroy, :id => notes(:open_note_with_comment).id, :text => "This is a hide comment", :format => "json"
    assert_response :forbidden

    basic_authorization(users(:moderator_user).email, "test")

    delete :destroy, :id => notes(:open_note_with_comment).id, :text => "This is a hide comment", :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "hidden", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "hidden", js["properties"]["comments"].last["action"]
    assert_equal "This is a hide comment", js["properties"]["comments"].last["text"]
    assert_equal "moderator", js["properties"]["comments"].last["user"]

    get :show, :id => notes(:open_note_with_comment).id, :format => "json"
    assert_response :gone
  end

  def test_destroy_fail
    delete :destroy, :id => 12345, :format => "json"
    assert_response :unauthorized

    basic_authorization(users(:public_user).email, "test")

    delete :destroy, :id => 12345, :format => "json"
    assert_response :forbidden

    basic_authorization(users(:moderator_user).email, "test")

    delete :destroy, :id => 12345, :format => "json"
    assert_response :not_found

    delete :destroy, :id => notes(:hidden_note_with_comment).id, :format => "json"
    assert_response :gone
  end

  def test_index_success
    get :index, :bbox => "1,1,1.2,1.2", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 2
      end
    end

    get :index, :bbox => "1,1,1.2,1.2", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 2, js["features"].count

    get :index, :bbox => "1,1,1.2,1.2", :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note", :count => 2
    end

    get :index, :bbox => "1,1,1.2,1.2", :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt", :count => 2
    end
  end

  def test_index_empty_area
    get :index, :bbox => "5,5,5.1,5.1", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 0
      end
    end

    get :index, :bbox => "5,5,5.1,5.1", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 0, js["features"].count

    get :index, :bbox => "5,5,5.1,5.1", :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note", :count => 0
    end

    get :index, :bbox => "5,5,5.1,5.1", :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt", :count => 0
    end
  end

  def test_index_large_area
    get :index, :bbox => "-2.5,-2.5,2.5,2.5", :format => :json
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :index, :l => "-2.5", :b => "-2.5", :r => "2.5", :t => "2.5", :format => :json
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :index, :bbox => "-10,-10,12,12", :format => :json
    assert_response :bad_request
    assert_equal "text/plain", @response.content_type

    get :index, :l => "-10", :b => "-10", :r => "12", :t => "12", :format => :json
    assert_response :bad_request
    assert_equal "text/plain", @response.content_type
  end

  def test_index_closed
    get :index, :bbox => "1,1,1.7,1.7", :closed => "7", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 4, js["features"].count

    get :index, :bbox => "1,1,1.7,1.7", :closed => "0", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 4, js["features"].count

    get :index, :bbox => "1,1,1.7,1.7", :closed => "-1", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 6, js["features"].count
  end

  def test_index_bad_params
    get :index, :bbox => "-2.5,-2.5,2.5"
    assert_response :bad_request

    get :index, :bbox => "-2.5,-2.5,2.5,2.5,2.5"
    assert_response :bad_request

    get :index, :b => "-2.5", :r => "2.5", :t => "2.5"
    assert_response :bad_request

    get :index, :l => "-2.5", :r => "2.5", :t => "2.5"
    assert_response :bad_request

    get :index, :l => "-2.5", :b => "-2.5", :t => "2.5"
    assert_response :bad_request

    get :index, :l => "-2.5", :b => "-2.5", :r => "2.5"
    assert_response :bad_request

    get :index, :bbox => "1,1,1.7,1.7", :limit => "0", :format => "json"
    assert_response :bad_request

    get :index, :bbox => "1,1,1.7,1.7", :limit => "10001", :format => "json"
    assert_response :bad_request
  end

  def test_search_success
    get :search, :q => "note 1", :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note", :count => 1
    end

    get :search, :q => "note 1", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 1, js["features"].count

    get :search, :q => "note 1", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 1
      end
    end

    get :search, :q => "note 1", :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt", :count => 1
    end
  end

  def test_search_no_match
    get :search, :q => "no match", :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note", :count => 0
    end

    get :search, :q => "no match", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 0, js["features"].count

    get :search, :q => "no match", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 0
      end
    end

    get :search, :q => "no match", :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt", :count => 0
    end
  end

  def test_search_bad_params
    get :search
    assert_response :bad_request

    get :search, :q => "no match", :limit => "0", :format => "json"
    assert_response :bad_request

    get :search, :q => "no match", :limit => "10001", :format => "json"
    assert_response :bad_request
  end

  def test_feed_success
    get :feed, :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 8
      end
    end

    get :feed, :bbox => "1,1,1.2,1.2", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 3
      end
    end
  end

  def test_feed_fail
    get :feed, :bbox => "1,1,1.2", :format => "rss"
    assert_response :bad_request

    get :feed, :bbox => "1,1,1.2,1.2,1.2", :format => "rss"
    assert_response :bad_request

    get :feed, :bbox => "1,1,1.2,1.2", :limit => "0", :format => "rss"
    assert_response :bad_request

    get :feed, :bbox => "1,1,1.2,1.2", :limit => "10001", :format => "rss"
    assert_response :bad_request
  end

  def test_mine_success
    get :mine, :display_name => "test"
    assert_response :success

    get :mine, :display_name => "pulibc_test2"
    assert_response :success

    get :mine, :display_name => "non-existent"
    assert_response :not_found
  end
end
