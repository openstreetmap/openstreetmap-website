require "test_helper"

class NoteTest < ActiveSupport::TestCase
  def test_status_valid
    ok = %w[open closed hidden]
    bad = %w[expropriated fubared]

    ok.each do |status|
      note = create(:note)
      note.status = status
      assert_predicate note, :valid?, "#{status} is invalid, when it should be"
    end

    bad.each do |status|
      note = create(:note)
      note.status = status
      assert_not_predicate note, :valid?, "#{status} is valid when it shouldn't be"
    end
  end

  def test_close
    note = create(:note)
    assert_equal "open", note.status
    assert_nil note.closed_at
    note.close
    assert_equal "closed", note.status
    assert_not_nil note.closed_at
  end

  def test_reopen
    note = create(:note, :closed)
    assert_equal "closed", note.status
    assert_not_nil note.closed_at
    note.reopen
    assert_equal "open", note.status
    assert_nil note.closed_at
  end

  def test_visible?
    assert_predicate create(:note, :status => "open"), :visible?
    assert_predicate create(:note, :closed), :visible?
    assert_not_predicate create(:note, :status => "hidden"), :visible?
  end

  def test_closed?
    assert_predicate create(:note, :closed), :closed?
    assert_not_predicate create(:note, :status => "open", :closed_at => nil), :closed?
  end

  def test_author
    comment = create(:note_comment)
    assert_nil comment.note.author

    user = create(:user)
    comment = create(:note_comment, :author => user)
    assert_equal user, comment.note.author
  end

  def test_author_ip
    comment = create(:note_comment)
    assert_nil comment.note.author_ip

    comment = create(:note_comment, :author_ip => IPAddr.new("192.168.1.1"))
    assert_equal IPAddr.new("192.168.1.1"), comment.note.author_ip
  end

  # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
  def test_lat_lon_format
    note = build(:note, :latitude => 0.00004 * GeoRecord::SCALE, :longitude => 0.00008 * GeoRecord::SCALE)

    assert_equal "0.0000400", note.lat.to_s
    assert_equal "0.0000800", note.lon.to_s
  end

  def test_filter_hidden_notes
    regular_user = create(:user)
    moderator_user = create(:user)

    moderator_user.roles.create(:role => "moderator", :granter_id => moderator_user.id)

    visible_note = create(:note, :status => "open")
    hidden_note = create(:note, :status => "hidden")

    filtered_notes = Note.filter_hidden_notes(regular_user)
    assert_includes filtered_notes, visible_note
    assert_not_includes filtered_notes, hidden_note

    filtered_notes = Note.filter_hidden_notes(moderator_user)
    assert_includes filtered_notes, visible_note
    assert_includes filtered_notes, hidden_note

    filtered_notes = Note.filter_hidden_notes(nil)
    assert_includes filtered_notes, visible_note
    assert_not_includes filtered_notes, hidden_note
  end

  def test_filter_by_status
    open_note = create(:note, :status => "open")
    closed_note = create(:note, :status => "closed")
    reopened_note = create(:note, :status => "open", :closed_at => 2.days.ago)

    filtered_notes = Note.filter_by_status("open")
    assert_includes filtered_notes, open_note
    assert_includes filtered_notes, reopened_note
    assert_not_includes filtered_notes, closed_note

    filtered_notes = Note.filter_by_status("closed")
    assert_includes filtered_notes, closed_note
    assert_not_includes filtered_notes, open_note
    assert_not_includes filtered_notes, reopened_note

    filtered_notes = Note.filter_by_status(nil)
    assert_includes filtered_notes, open_note
    assert_includes filtered_notes, closed_note
    assert_includes filtered_notes, reopened_note
  end

  def test_filter_by_note_type
    user = create(:user)
    other_user = create(:user)
    anonymous_user = nil

    submitted_note = create(:note) do |note|
      create(:note_comment, :note => note, :author => user)
    end

    commented_note = create(:note) do |note|
      create(:note_comment, :note => note, :author => other_user)
      create(:note_comment, :note => note, :author => user)
    end

    anonymous_commented_note = create(:note) do |note|
      create(:note_comment, :note => note, :author => anonymous_user)
      create(:note_comment, :note => note, :author => user)
    end

    filtered_notes = Note.filter_by_note_type("submitted", user.id)
    assert_includes filtered_notes, submitted_note
    assert_not_includes filtered_notes, commented_note
    assert_not_includes filtered_notes, anonymous_commented_note

    filtered_notes = Note.filter_by_note_type("commented", user.id)
    assert_includes filtered_notes, commented_note
    assert_includes filtered_notes, anonymous_commented_note
    assert_not_includes filtered_notes, submitted_note

    filtered_notes = Note.filter_by_note_type(nil, user.id)
    assert_includes filtered_notes, submitted_note
    assert_includes filtered_notes, commented_note
    assert_includes filtered_notes, anonymous_commented_note
  end

  def test_filter_by_date_range
    old_note = create(:note, :created_at => 2.years.ago)
    middle_note = create(:note, :created_at => 1.year.ago)
    recent_note = create(:note, :created_at => 1.day.ago)
    very_recent_note = create(:note, :created_at => 2.hours.ago)

    filtered_notes = Note.filter_by_date_range(2.days.ago.to_s, nil)
    assert_includes filtered_notes, recent_note
    assert_includes filtered_notes, very_recent_note
    assert_not_includes filtered_notes, middle_note
    assert_not_includes filtered_notes, old_note

    filtered_notes = Note.filter_by_date_range(1.year.ago.to_s, nil)
    assert_includes filtered_notes, middle_note
    assert_includes filtered_notes, recent_note
    assert_includes filtered_notes, very_recent_note
    assert_not_includes filtered_notes, old_note

    filtered_notes = Note.filter_by_date_range(2.years.ago.to_s, 6.months.ago.to_s)
    assert_includes filtered_notes, old_note
    assert_includes filtered_notes, middle_note
    assert_not_includes filtered_notes, recent_note
    assert_not_includes filtered_notes, very_recent_note

    filtered_notes = Note.filter_by_date_range(1.day.ago.to_s, Time.current.to_s)
    assert_includes filtered_notes, recent_note
    assert_includes filtered_notes, very_recent_note
    assert_not_includes filtered_notes, old_note
    assert_not_includes filtered_notes, middle_note
  end

  def test_sort_by_params
    older_note = create(:note, :updated_at => 2.days.ago, :created_at => 5.days.ago)
    newer_note = create(:note, :updated_at => 1.day.ago, :created_at => 4.days.ago)
    latest_note = create(:note, :updated_at => 1.hour.ago, :created_at => 1.day.ago)

    filtered_notes = Note.sort_by_params("updated_at", "asc")
    assert_equal filtered_notes.first, older_note
    assert_equal filtered_notes.second, newer_note
    assert_equal filtered_notes.last, latest_note

    filtered_notes = Note.sort_by_params("updated_at", "desc")
    assert_equal filtered_notes.first, latest_note
    assert_equal filtered_notes.second, newer_note
    assert_equal filtered_notes.last, older_note

    filtered_notes = Note.sort_by_params("created_at", "asc")
    assert_equal filtered_notes.first, older_note
    assert_equal filtered_notes.second, newer_note
    assert_equal filtered_notes.last, latest_note

    filtered_notes = Note.sort_by_params("created_at", "desc")
    assert_equal filtered_notes.first, latest_note
    assert_equal filtered_notes.second, newer_note
    assert_equal filtered_notes.last, older_note

    filtered_notes = Note.sort_by_params(nil, nil)
    assert_equal filtered_notes.first, latest_note
    assert_equal filtered_notes.second, newer_note
    assert_equal filtered_notes.last, older_note
  end
end
