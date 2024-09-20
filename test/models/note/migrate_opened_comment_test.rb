require "test_helper"

class NoteMigrateOpenedCommentTest < ActiveSupport::TestCase
  def test_copies_body_and_author_information_from_the_opened_comment_note
    note = create(:note, :body => nil, :author => nil, :author_ip => nil)
    note_opened_comment = create(:note_comment, :note => note, :event => "opened", :body => "Hey hey!", :author => create(:user), :author_ip => "10.0.0.1")

    assert Note::MigrateOpenedComment.new(note).call
    assert_equal note_opened_comment.body, note.body
    assert_equal note_opened_comment.author, note.author
    assert_equal note_opened_comment.author_ip, note.author_ip
  end

  def test_skip_returns_true_if_no_opened_comment_does_not_exist
    note = create(:note)
    migration = Note::MigrateOpenedComment.new(note)

    assert_predicate migration, :skip?
  end

  def test_skip_returns_false_if_opened_comment_exists
    note = create(:note)
    create(:note_comment, :note => note, :event => "opened")
    migration = Note::MigrateOpenedComment.new(note)

    assert_not_predicate migration, :skip?
  end

  def test_comments_after_migration
    note = create(:note, :body => nil, :author => nil, :author_ip => nil)
    create(:note_comment, :note => note, :event => "opened", :body => "Hey hey!", :author => create(:user), :author_ip => "10.0.0.1")
    create(:note_comment, :note => note, :event => "commented", :body => "done", :author => create(:user), :author_ip => "10.0.0.2")

    note.reload
    assert_equal 2, note.comments.length

    assert Note::MigrateOpenedComment.new(note).call

    n = Note.find(note.id) # ensure association cache is avoided
    assert_equal 2, n.comments.length
  end
end
