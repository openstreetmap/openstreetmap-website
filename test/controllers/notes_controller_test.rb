require "test_helper"

class NotesControllerTest < ActionController::TestCase
  def setup
    # Stub nominatim response for note locations
    stub_request(:get, %r{^http://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)
  end

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

    assert_no_difference "Note.count" do
      assert_no_difference "NoteComment.count" do
        post :create, :lat => -1.0, :lon => -1.0, :text => "x\u0000y"
      end
    end
    assert_response :bad_request
  end

  def test_comment_success
    open_note_with_comment = create(:note_with_comments)
    assert_difference "NoteComment.count", 1 do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post :comment, :id => open_note_with_comment.id, :text => "This is an additional comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal open_note_with_comment.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    get :show, :id => open_note_with_comment.id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal open_note_with_comment.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    # Ensure that emails are sent to users
    first_user = create(:user)
    second_user = create(:user)
    third_user = create(:user)

    note_with_comments_by_users = create(:note) do |note|
      create(:note_comment, :note => note, :author => first_user)
      create(:note_comment, :note => note, :author => second_user)
    end
    assert_difference "NoteComment.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 2 do
        post :comment, :id => note_with_comments_by_users.id, :text => "This is an additional comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal note_with_comments_by_users.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == first_user.email }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] An anonymous user has commented on one of your notes", email.subject

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == second_user.email }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] An anonymous user has commented on a note you are interested in", email.subject

    get :show, :id => note_with_comments_by_users.id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal note_with_comments_by_users.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    ActionMailer::Base.deliveries.clear

    basic_authorization(third_user.email, "test")

    assert_difference "NoteComment.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 2 do
        post :comment, :id => note_with_comments_by_users.id, :text => "This is an additional comment", :format => "json"
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal note_with_comments_by_users.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 4, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_equal third_user.display_name, js["properties"]["comments"].last["user"]

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == first_user.email }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] #{third_user.display_name} has commented on one of your notes", email.subject
    assert_equal first_user.email, email.to.first

    email = ActionMailer::Base.deliveries.find { |e| e.to.first == second_user.email }
    assert_not_nil email
    assert_equal 1, email.to.length
    assert_equal "[OpenStreetMap] #{third_user.display_name} has commented on a note you are interested in", email.subject

    get :show, :id => note_with_comments_by_users.id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal note_with_comments_by_users.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 4, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_equal third_user.display_name, js["properties"]["comments"].last["user"]

    ActionMailer::Base.deliveries.clear
  end

  def test_comment_fail
    open_note_with_comment = create(:note_with_comments)

    assert_no_difference "NoteComment.count" do
      post :comment, :text => "This is an additional comment"
    end
    assert_response :bad_request

    assert_no_difference "NoteComment.count" do
      post :comment, :id => open_note_with_comment.id
    end
    assert_response :bad_request

    assert_no_difference "NoteComment.count" do
      post :comment, :id => open_note_with_comment.id, :text => ""
    end
    assert_response :bad_request

    assert_no_difference "NoteComment.count" do
      post :comment, :id => 12345, :text => "This is an additional comment"
    end
    assert_response :not_found

    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    assert_no_difference "NoteComment.count" do
      post :comment, :id => hidden_note_with_comment.id, :text => "This is an additional comment"
    end
    assert_response :gone

    closed_note_with_comment = create(:note_with_comments, :status => "closed", :closed_at => Time.now)

    assert_no_difference "NoteComment.count" do
      post :comment, :id => closed_note_with_comment.id, :text => "This is an additional comment"
    end
    assert_response :conflict

    assert_no_difference "NoteComment.count" do
      post :comment, :id => open_note_with_comment.id, :text => "x\u0000y"
    end
    assert_response :bad_request
  end

  def test_close_success
    open_note_with_comment = create(:note_with_comments)
    user = create(:user)

    post :close, :id => open_note_with_comment.id, :text => "This is a close comment", :format => "json"
    assert_response :unauthorized

    basic_authorization(user.email, "test")

    post :close, :id => open_note_with_comment.id, :text => "This is a close comment", :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal open_note_with_comment.id, js["properties"]["id"]
    assert_equal "closed", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "closed", js["properties"]["comments"].last["action"]
    assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
    assert_equal user.display_name, js["properties"]["comments"].last["user"]

    get :show, :id => open_note_with_comment.id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal open_note_with_comment.id, js["properties"]["id"]
    assert_equal "closed", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "closed", js["properties"]["comments"].last["action"]
    assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
    assert_equal user.display_name, js["properties"]["comments"].last["user"]
  end

  def test_close_fail
    post :close
    assert_response :unauthorized

    basic_authorization(create(:user).email, "test")

    post :close
    assert_response :bad_request

    post :close, :id => 12345
    assert_response :not_found

    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    post :close, :id => hidden_note_with_comment.id
    assert_response :gone

    closed_note_with_comment = create(:note_with_comments, :status => "closed", :closed_at => Time.now)

    post :close, :id => closed_note_with_comment.id
    assert_response :conflict
  end

  def test_reopen_success
    closed_note_with_comment = create(:note_with_comments, :status => "closed", :closed_at => Time.now)
    user = create(:user)

    post :reopen, :id => closed_note_with_comment.id, :text => "This is a reopen comment", :format => "json"
    assert_response :unauthorized

    basic_authorization(user.email, "test")

    post :reopen, :id => closed_note_with_comment.id, :text => "This is a reopen comment", :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal closed_note_with_comment.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "reopened", js["properties"]["comments"].last["action"]
    assert_equal "This is a reopen comment", js["properties"]["comments"].last["text"]
    assert_equal user.display_name, js["properties"]["comments"].last["user"]

    get :show, :id => closed_note_with_comment.id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal closed_note_with_comment.id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "reopened", js["properties"]["comments"].last["action"]
    assert_equal "This is a reopen comment", js["properties"]["comments"].last["text"]
    assert_equal user.display_name, js["properties"]["comments"].last["user"]
  end

  def test_reopen_fail
    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    post :reopen, :id => hidden_note_with_comment.id
    assert_response :unauthorized

    basic_authorization(create(:user).email, "test")

    post :reopen, :id => 12345
    assert_response :not_found

    post :reopen, :id => hidden_note_with_comment.id
    assert_response :gone

    open_note_with_comment = create(:note_with_comments)

    post :reopen, :id => open_note_with_comment.id
    assert_response :conflict
  end

  def test_show_success
    open_note = create(:note_with_comments)

    get :show, :id => open_note.id, :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note[lat='#{open_note.lat}'][lon='#{open_note.lon}']", :count => 1 do
        assert_select "id", open_note.id.to_s
        assert_select "url", note_url(open_note, :format => "xml")
        assert_select "comment_url", comment_note_url(open_note, :format => "xml")
        assert_select "close_url", close_note_url(open_note, :format => "xml")
        assert_select "date_created", open_note.created_at.to_s
        assert_select "status", open_note.status
        assert_select "comments", :count => 1 do
          assert_select "comment", :count => 1
        end
      end
    end

    get :show, :id => open_note.id, :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 1 do
          assert_select "link", browse_note_url(open_note)
          assert_select "guid", note_url(open_note)
          assert_select "pubDate", open_note.created_at.to_s(:rfc822)
          #          assert_select "geo:lat", open_note.lat.to_s
          #          assert_select "geo:long", open_note.lon
          #          assert_select "georss:point", "#{open_note.lon} #{open_note.lon}"
        end
      end
    end

    get :show, :id => open_note.id, :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal "Point", js["geometry"]["type"]
    assert_equal open_note.lat, js["geometry"]["coordinates"][0]
    assert_equal open_note.lon, js["geometry"]["coordinates"][1]
    assert_equal open_note.id, js["properties"]["id"]
    assert_equal note_url(open_note, :format => "json"), js["properties"]["url"]
    assert_equal comment_note_url(open_note, :format => "json"), js["properties"]["comment_url"]
    assert_equal close_note_url(open_note, :format => "json"), js["properties"]["close_url"]
    assert_equal open_note.created_at.to_s, js["properties"]["date_created"]
    assert_equal open_note.status, js["properties"]["status"]

    get :show, :id => open_note.id, :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt[lat='#{open_note.lat}'][lon='#{open_note.lon}']", :count => 1 do
        assert_select "time", :count => 1
        assert_select "name", "Note: #{open_note.id}"
        assert_select "desc", :count => 1
        assert_select "link[href='http://test.host/note/#{open_note.id}']", :count => 1
        assert_select "extensions", :count => 1 do
          assert_select "id", open_note.id.to_s
          assert_select "url", note_url(open_note, :format => "gpx")
          assert_select "comment_url", comment_note_url(open_note, :format => "gpx")
          assert_select "close_url", close_note_url(open_note, :format => "gpx")
        end
      end
    end
  end

  def test_show_hidden_comment
    note_with_hidden_comment = create(:note) do |note|
      create(:note_comment, :note => note, :body => "Valid comment for hidden note")
      create(:note_comment, :note => note, :visible => false)
      create(:note_comment, :note => note, :body => "Another valid comment for hidden note")
    end

    get :show, :id => note_with_hidden_comment.id, :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal note_with_hidden_comment.id, js["properties"]["id"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "Valid comment for hidden note", js["properties"]["comments"][0]["text"]
    assert_equal "Another valid comment for hidden note", js["properties"]["comments"][1]["text"]
  end

  def test_show_fail
    get :show, :id => 12345
    assert_response :not_found

    get :show, :id => create(:note, :status => "hidden").id
    assert_response :gone
  end

  def test_destroy_success
    open_note_with_comment = create(:note_with_comments)
    user = create(:user)
    moderator_user = create(:moderator_user)

    delete :destroy, :id => open_note_with_comment.id, :text => "This is a hide comment", :format => "json"
    assert_response :unauthorized

    basic_authorization(user.email, "test")

    delete :destroy, :id => open_note_with_comment.id, :text => "This is a hide comment", :format => "json"
    assert_response :forbidden

    basic_authorization(moderator_user.email, "test")

    delete :destroy, :id => open_note_with_comment.id, :text => "This is a hide comment", :format => "json"
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal open_note_with_comment.id, js["properties"]["id"]
    assert_equal "hidden", js["properties"]["status"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "hidden", js["properties"]["comments"].last["action"]
    assert_equal "This is a hide comment", js["properties"]["comments"].last["text"]
    assert_equal moderator_user.display_name, js["properties"]["comments"].last["user"]

    get :show, :id => open_note_with_comment.id, :format => "json"
    assert_response :gone
  end

  def test_destroy_fail
    user = create(:user)
    moderator_user = create(:moderator_user)

    delete :destroy, :id => 12345, :format => "json"
    assert_response :unauthorized

    basic_authorization(user.email, "test")

    delete :destroy, :id => 12345, :format => "json"
    assert_response :forbidden

    basic_authorization(moderator_user.email, "test")

    delete :destroy, :id => 12345, :format => "json"
    assert_response :not_found

    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    delete :destroy, :id => hidden_note_with_comment.id, :format => "json"
    assert_response :gone
  end

  def test_index_success
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note_with_comments, :latitude => position, :longitude => position)
    create(:note_with_comments, :latitude => position, :longitude => position)

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

  def test_index_limit
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note_with_comments, :latitude => position, :longitude => position)
    create(:note_with_comments, :latitude => position, :longitude => position)

    get :index, :bbox => "1,1,1.2,1.2", :limit => 1, :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 1
      end
    end

    get :index, :bbox => "1,1,1.2,1.2", :limit => 1, :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 1, js["features"].count

    get :index, :bbox => "1,1,1.2,1.2", :limit => 1, :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note", :count => 1
    end

    get :index, :bbox => "1,1,1.2,1.2", :limit => 1, :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt", :count => 1
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
    create(:note_with_comments, :status => "closed", :closed_at => Time.now - 5.days)
    create(:note_with_comments, :status => "closed", :closed_at => Time.now - 100.days)
    create(:note_with_comments, :status => "hidden")
    create(:note_with_comments)

    # Open notes + closed in last 7 days
    get :index, :bbox => "1,1,1.7,1.7", :closed => "7", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 2, js["features"].count

    # Only open notes
    get :index, :bbox => "1,1,1.7,1.7", :closed => "0", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 1, js["features"].count

    # Open notes + all closed notes
    get :index, :bbox => "1,1,1.7,1.7", :closed => "-1", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 3, js["features"].count
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
    create(:note_with_comments)

    get :search, :q => "note comment", :format => "xml"
    assert_response :success
    assert_equal "application/xml", @response.content_type
    assert_select "osm", :count => 1 do
      assert_select "note", :count => 1
    end

    get :search, :q => "note comment", :format => "json"
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 1, js["features"].count

    get :search, :q => "note comment", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 1
      end
    end

    get :search, :q => "note comment", :format => "gpx"
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
    assert_select "gpx", :count => 1 do
      assert_select "wpt", :count => 1
    end
  end

  def test_search_no_match
    create(:note_with_comments)

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
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note_with_comments, :latitude => position, :longitude => position)
    create(:note_with_comments, :latitude => position, :longitude => position)
    position = (1.5 * GeoRecord::SCALE).to_i
    create(:note_with_comments, :latitude => position, :longitude => position)
    create(:note_with_comments, :latitude => position, :longitude => position)

    get :feed, :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 4
      end
    end

    get :feed, :bbox => "1,1,1.2,1.2", :format => "rss"
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "item", :count => 2
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
    first_user = create(:user)
    second_user = create(:user)
    moderator_user = create(:moderator_user)

    create(:note) do |note|
      create(:note_comment, :note => note, :author => first_user)
    end
    create(:note) do |note|
      create(:note_comment, :note => note, :author => second_user)
    end
    create(:note, :status => "hidden") do |note|
      create(:note_comment, :note => note, :author => second_user)
    end

    # Note that the table rows include a header row
    get :mine, :display_name => first_user.display_name
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get :mine, :display_name => second_user.display_name
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get :mine, :display_name => "non-existent"
    assert_response :not_found

    session[:user] = moderator_user.id

    get :mine, :display_name => first_user.display_name
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get :mine, :display_name => second_user.display_name
    assert_response :success
    assert_select "table.note_list tr", :count => 3

    get :mine, :display_name => "non-existent"
    assert_response :not_found
  end
end
