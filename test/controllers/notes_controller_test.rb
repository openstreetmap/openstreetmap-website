require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    # Stub nominatim response for note locations
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)
  end

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/notes", :method => :get },
      { :controller => "notes", :action => "index", :display_name => "username" }
    )
    assert_routing(
      { :path => "/note/1", :method => :get },
      { :controller => "notes", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/note/new", :method => :get },
      { :controller => "notes", :action => "new" }
    )
  end

  def test_index_success
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
    get user_notes_path(:display_name => first_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get user_notes_path(:display_name => second_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get user_notes_path(:display_name => "non-existent")
    assert_response :not_found

    session_for(moderator_user)

    get user_notes_path(:display_name => first_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 2

    get user_notes_path(:display_name => second_user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 3

    get user_notes_path(:display_name => "non-existent")
    assert_response :not_found
  end

  def test_index_paged
    user = create(:user)

    create_list(:note, 50) do |note|
      create(:note_comment, :note => note, :author => user)
    end

    get user_notes_path(:display_name => user.display_name)
    assert_response :success
    assert_select "table.note_list tr", :count => 11

    get user_notes_path(:display_name => user.display_name, :page => 2)
    assert_response :success
    assert_select "table.note_list tr", :count => 11
  end

  def test_empty_page
    user = create(:user)
    get user_notes_path(:display_name => user.display_name)
    assert_response :success
    assert_select "h4", :html => "No notes"
  end

  def test_read_note
    open_note = create(:note_with_comments)

    browse_check :note_path, open_note.id, "notes/show"
  end

  def test_read_hidden_note
    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    get note_path(:id => hidden_note_with_comment)
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    get note_path(:id => hidden_note_with_comment), :xhr => true
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    session_for(create(:moderator_user))

    browse_check :note_path, hidden_note_with_comment.id, "notes/show"
  end

  def test_read_note_hidden_comments
    note_with_hidden_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :visible => false)
    end

    browse_check :note_path, note_with_hidden_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1

    session_for(create(:moderator_user))

    browse_check :note_path, note_with_hidden_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 2
  end

  def test_read_note_hidden_user_comment
    hidden_user = create(:user, :deleted)
    note_with_hidden_user_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :author => hidden_user)
    end

    browse_check :note_path, note_with_hidden_user_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1

    session_for(create(:moderator_user))

    browse_check :note_path, note_with_hidden_user_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1
  end

  def test_read_closed_note
    user = create(:user)
    closed_note = create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc, :comments_count => 2) do |note|
      create(:note_comment, :event => "closed", :note => note, :author => user)
    end

    browse_check :note_path, closed_note.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 2
    assert_select "div.details", /Resolved by #{user.display_name}/

    user.soft_destroy!

    reset!

    browse_check :note_path, closed_note.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1
    assert_select "div.details", /Resolved by deleted/
  end

  def test_new_note
    get new_note_path
    assert_response :success
    assert_template "notes/new"
  end

  private

  # This is a convenience method for most of the above checks
  # First we check that when we don't have an id, it will correctly return a 404
  # then we check that we get the correct 404 when a non-existant id is passed
  # then we check that it will get a successful response, when we do pass an id
  def browse_check(path, id, template)
    path_method = method(path)

    assert_raise ActionController::UrlGenerationError do
      get path_method.call
    end

    # assert_raise ActionController::UrlGenerationError do
    #   get path_method.call(:id => -10) # we won't have an id that's negative
    # end

    get path_method.call(:id => 0)
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    get path_method.call(:id => 0), :xhr => true
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    get path_method.call(:id => id)
    assert_response :success
    assert_template template
    assert_template :layout => "map"

    get path_method.call(:id => id), :xhr => true
    assert_response :success
    assert_template template
    assert_template :layout => "xhr"
  end
end
