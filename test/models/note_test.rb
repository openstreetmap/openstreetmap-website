# frozen_string_literal: true

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

  def test_description
    note = create(:note)
    assert_equal "Default note's description", note.description

    note = create(:note, :description => "Test description #1")
    assert_equal "Test description #1", note.description

    comment = create(:note_comment)
    assert_equal "Default note's description", comment.note.description

    comment = create(:note_comment, :note => build(:note, :description => "Test description #2"))
    assert_equal "Test description #2", comment.note.description
  end

  def test_author
    user = create(:user)

    note = create(:note, :author => user)
    assert_equal user, note.author

    comment = create(:note_comment)
    assert_nil comment.note.author

    comment = create(:note_comment, :author => user, :note => build(:note, :author => user))
    assert_equal user, comment.note.author
  end

  # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
  def test_lat_lon_format
    note = build(:note, :latitude => 0.00004 * GeoRecord::SCALE, :longitude => 0.00008 * GeoRecord::SCALE)

    assert_equal "0.0000400", note.lat.to_s
    assert_equal "0.0000800", note.lon.to_s
  end
end
