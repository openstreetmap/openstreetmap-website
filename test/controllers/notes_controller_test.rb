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

    note1 = create(:note) do |note|
      create(:note_comment, :note => note, :author => first_user)
    end
    note2 = create(:note) do |note|
      create(:note_comment, :note => note, :author => second_user)
    end
    note3 = create(:note, :status => "hidden") do |note|
      create(:note_comment, :note => note, :author => second_user)
    end

    get user_notes_path(first_user)
    assert_response :success
    assert_select ".content-heading a[href='#{user_path first_user}']", :text => first_user.display_name
    check_note_table [note1]

    get user_notes_path(second_user)
    assert_response :success
    assert_select ".content-heading a[href='#{user_path second_user}']", :text => second_user.display_name
    check_note_table [note2]

    get user_notes_path("non-existent")
    assert_response :not_found

    session_for(moderator_user)

    get user_notes_path(first_user)
    assert_response :success
    check_note_table [note1]

    get user_notes_path(second_user)
    assert_response :success
    check_note_table [note3, note2]

    get user_notes_path("non-existent")
    assert_response :not_found
  end

  def test_index_paged
    user = create(:user)

    notes = create_list(:note, 20) do |note|
      create(:note_comment, :note => note, :author => user)
    end

    next_path = user_notes_path(user)

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[0..9]
      check_no_newer_notes
      next_path = check_older_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[10..19]
      check_no_older_notes
      next_path = check_newer_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[0..9]
      check_no_newer_notes
      next_path = check_older_notes
    end
  end

  def test_index_before_edge
    user = create(:user)

    notes = Array.new(11) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end

    next_path = user_notes_path(user, :to => "newest")

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[0..9]
      check_no_newer_notes
      next_path = check_older_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes.reverse[10]]
      check_no_older_notes
      next_path = check_newer_notes
    end
  end

  def test_index_after_edge
    user = create(:user)

    notes = Array.new(11) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end

    next_path = user_notes_path(user, :from => "oldest")

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[1..10]
      check_no_older_notes
      next_path = check_newer_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes.reverse[0]]
      check_no_newer_notes
      next_path = check_older_notes
    end
  end

  def test_index_before_id
    user = create(:user)

    notes = Array.new(2) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end

    next_path = user_notes_path(user, :before => notes[1].id)

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[0]]
      check_no_older_notes
      next_path = check_newer_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[1]]
      check_no_newer_notes
      next_path = check_older_notes
    end
  end

  def test_index_before_id_empty_page
    user = create(:user)

    notes = Array.new(2) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end

    next_path = user_notes_path(user, :before => notes[0].id)

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_no_note_table
      check_no_older_notes
      next_path = check_newer_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[1], notes[0]]
      check_no_newer_notes
      check_no_older_notes
    end
  end

  def test_index_after_id
    user = create(:user)

    notes = Array.new(2) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end

    next_path = user_notes_path(user, :after => notes[0].id)

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[1]]
      check_no_newer_notes
      next_path = check_older_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[0]]
      check_no_older_notes
      next_path = check_newer_notes
    end
  end

  def test_index_after_id_empty_page
    user = create(:user)

    notes = Array.new(2) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end

    next_path = user_notes_path(user, :after => notes[1].id)

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_no_note_table
      check_no_newer_notes
      next_path = check_older_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[1], notes[0]]
      check_no_older_notes
      check_no_newer_notes
    end
  end

  def test_index_updated_cursor
    user = create(:user)

    freeze_time
    travel(-1.year)
    notes = Array.new(20) do
      travel 1.day
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end
    unfreeze_time

    next_path = user_notes_path(user)

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[0..9]
      check_no_newer_notes
      next_path = check_older_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[10..19]
      check_no_older_notes
      next_path = check_newer_notes
    end

    updated_note = notes.reverse[10]
    updated_note.updated_at = Time.now.utc
    updated_note.save!

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse[0..9]
      check_older_notes
      next_path = check_newer_notes
    end

    get next_path
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes.reverse[10]]
      check_no_newer_notes
      check_older_notes
    end
  end

  def test_index_empty_page
    user = create(:user)
    get user_notes_path(user)
    assert_response :success
    assert_select ".content-body" do
      check_no_note_table
      check_no_newer_notes
      check_no_older_notes
    end
  end

  def test_index_invalid_cursor
    user = create(:user)
    other_user = create(:user)
    other_users_note = create(:note) do |note|
      create(:note_comment, :note => note, :author => other_user)
    end
    hidden_note = create(:note, :status => "hidden") do |note|
      create(:note_comment, :note => note, :author => user)
    end

    get user_notes_path(user, :before => 0)
    assert_redirected_to :action => :index

    get user_notes_path(user, :after => 0)
    assert_redirected_to :action => :index

    get user_notes_path(user, :before => other_users_note.id)
    assert_redirected_to :action => :index

    get user_notes_path(user, :after => other_users_note.id)
    assert_redirected_to :action => :index

    get user_notes_path(user, :before => hidden_note.id)
    assert_redirected_to :action => :index

    get user_notes_path(user, :after => hidden_note.id)
    assert_redirected_to :action => :index
  end

  def test_same_time
    user = create(:user)

    freeze_time
    notes = Array.new(2) do
      note = create(:note)
      create(:note_comment, :note => note, :author => user)
      note
    end
    unfreeze_time

    get user_notes_path(user)
    assert_response :success
    assert_select ".content-body" do
      check_note_table notes.reverse
      check_no_newer_notes
      check_no_older_notes
    end

    get user_notes_path(user, :before => notes[1].id)
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[0]]
      check_newer_notes
      check_no_older_notes
    end

    get user_notes_path(user, :after => notes[0].id)
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[1]]
      check_no_newer_notes
      check_older_notes
    end

    get user_notes_path(user, :to => notes[0].id)
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[0]]
      check_newer_notes
      check_no_older_notes
    end

    get user_notes_path(user, :from => notes[1].id)
    assert_response :success
    assert_select ".content-body" do
      check_note_table [notes[1]]
      check_no_newer_notes
      check_older_notes
    end
  end

  def test_read_note
    open_note = create(:note_with_comments)

    browse_check :note_path, open_note.id, "notes/show"
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
    closed_note = create(:note_with_comments, :closed, :closed_by => user, :comments_count => 2)

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

  def check_no_note_table
    assert_select "h4", :html => "No notes"
  end

  def check_note_table(notes)
    assert_dom "table.note_list tbody tr" do |rows|
      table_ids = rows.map do |row|
        cell = assert_dom row, "> td:nth-child(2)", :text => /^\d+$/
        cell.text.to_i
      end
      assert_equal notes.map(&:id), table_ids, "notes table mismatch"
    end
  end

  def check_no_older_notes
    assert_select "a.page-link", :text => /Older Notes/, :count => 0
  end

  def check_no_newer_notes
    assert_select "a.page-link", :text => /Newer Notes/, :count => 0
  end

  def check_older_notes
    path = nil
    assert_select "a.page-link", { :text => /Older Notes/ }, "missing older notes link" do |buttons|
      path = buttons.first.attributes["href"].value
    end
    path
  end

  def check_newer_notes
    path = nil
    assert_select "a.page-link", { :text => /Newer Notes/ }, "missing newer notes link" do |buttons|
      path = buttons.first.attributes["href"].value
    end
    path
  end
end
