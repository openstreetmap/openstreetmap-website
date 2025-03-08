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

    get user_notes_path(first_user)
    assert_response :success
    assert_select ".content-heading a[href='#{user_path first_user}']", :text => first_user.display_name
    assert_select "table.note_list tbody tr", :count => 1

    get user_notes_path(second_user)
    assert_response :success
    assert_select ".content-heading a[href='#{user_path second_user}']", :text => second_user.display_name
    assert_select "table.note_list tbody tr", :count => 1

    get user_notes_path("non-existent")
    assert_response :not_found

    session_for(moderator_user)

    get user_notes_path(first_user)
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 1

    get user_notes_path(second_user)
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 2

    get user_notes_path("non-existent")
    assert_response :not_found
  end

  def test_index_paged
    user = create(:user)

    create_list(:note, 50) do |note|
      create(:note_comment, :note => note, :author => user)
    end

    get user_notes_path(user)
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 10

    get user_notes_path(user, :page => 2)
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 10
  end

  def test_index_invalid_paged
    user = create(:user)

    %w[-1 0 fred].each do |page|
      get user_notes_path(user, :page => page)
      assert_redirected_to :controller => :errors, :action => :bad_request
    end
  end

  def test_empty_page
    user = create(:user)
    get user_notes_path(user)
    assert_response :success
    assert_select "h4", :html => "No notes"
  end

  def test_read_note
    open_note = create(:note_with_comments)

    sidebar_browse_check :note_path, open_note.id, "notes/show"
  end

  def test_read_hidden_note
    hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

    get note_path(hidden_note_with_comment)
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"

    get note_path(hidden_note_with_comment), :xhr => true
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "xhr"

    session_for(create(:moderator_user))

    sidebar_browse_check :note_path, hidden_note_with_comment.id, "notes/show"
  end

  def test_read_note_hidden_comments
    note_with_hidden_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :visible => false)
    end

    sidebar_browse_check :note_path, note_with_hidden_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1

    session_for(create(:moderator_user))

    sidebar_browse_check :note_path, note_with_hidden_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 2
  end

  def test_read_note_hidden_user_comment
    hidden_user = create(:user, :deleted)
    note_with_hidden_user_comment = create(:note_with_comments, :comments_count => 2) do |note|
      create(:note_comment, :note => note, :author => hidden_user)
    end

    sidebar_browse_check :note_path, note_with_hidden_user_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1

    session_for(create(:moderator_user))

    sidebar_browse_check :note_path, note_with_hidden_user_comment.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1
  end

  def test_read_note_hidden_opener
    hidden_user = create(:user, :deleted)
    note_with_hidden_opener = create(:note)
    create(:note_comment, :author => hidden_user, :note => note_with_hidden_opener)

    sidebar_browse_check :note_path, note_with_hidden_opener.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 0
  end

  def test_read_note_suspended_opener_and_comment
    note = create(:note)
    create(:note_comment, :note => note, :author => create(:user, :suspended))
    create(:note_comment, :note => note, :event => "commented")

    sidebar_browse_check :note_path, note.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1
  end

  def test_read_closed_note
    user = create(:user)
    closed_note = create(:note_with_comments, :closed, :closed_by => user, :comments_count => 2)

    sidebar_browse_check :note_path, closed_note.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 2
    assert_select "div.details", /Resolved by #{user.display_name}/

    user.soft_destroy!

    reset!

    sidebar_browse_check :note_path, closed_note.id, "notes/show"
    assert_select "div.note-comments ul li", :count => 1
    assert_select "div.details", /Resolved by deleted/
  end

  def test_new_note_anonymous
    get new_note_path
    assert_response :success
    assert_template "notes/new"
    assert_select "#sidebar_content a[href='#{login_path(:referer => new_note_path)}']", :count => 1
  end

  def test_new_note
    session_for(create(:user))

    get new_note_path
    assert_response :success
    assert_template "notes/new"
    assert_select "#sidebar_content a[href='#{login_path(:referer => new_note_path)}']", :count => 0
  end

  def test_index_filter_by_status
    user = create(:user)
    other_user = create(:user)

    open_note = create(:note, :status => "open")
    create(:note_comment, :note => open_note, :author => user)

    closed_note = create(:note, :status => "closed")
    create(:note_comment, :note => closed_note, :author => user)

    hidden_note = create(:note, :status => "hidden")
    create(:note_comment, :note => hidden_note, :author => user)

    commented_note = create(:note, :status => "open")
    create(:note_comment, :note => commented_note, :author => other_user)
    create(:note_comment, :note => commented_note, :author => user)

    get user_notes_path(user, :status => "all")
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 3

    get user_notes_path(user, :status => "open")
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 2

    get user_notes_path(user, :status => "closed")
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 1

    get user_notes_path(user)
    assert_response :success
    assert_select "table.note_list tbody tr", :count => 3
  end
end
