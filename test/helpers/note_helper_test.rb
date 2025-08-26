require "test_helper"

class NoteHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  def test_note_event
    date = Time.utc(2014, 3, 5, 21, 37, 45)
    user = create(:user)

    note_event_dom = Rails::Dom::Testing.html_document_fragment.parse "<div>#{note_event('opened', date, nil)}</div>"
    assert_dom note_event_dom, ":root", :text => /^Created by anonymous .* ago$/ do
      assert_dom "> a", :count => 0
      assert_dom "> time", :count => 1 do
        assert_dom "> @title", "5 March 2014 at 21:37"
        assert_dom "> @datetime", "2014-03-05T21:37:45Z"
      end
    end

    note_event_dom = Rails::Dom::Testing.html_document_fragment.parse "<div>#{note_event('closed', date, user)}</div>"
    assert_dom note_event_dom, ":root", :text => /^Resolved by #{user.display_name} .* ago$/ do
      assert_dom "> a", :count => 1, :text => user.display_name do
        assert_dom "> @href", "/user/#{ERB::Util.u(user.display_name)}"
      end
      assert_dom "> time", :count => 1 do
        assert_dom "> @title", "5 March 2014 at 21:37"
        assert_dom "> @datetime", "2014-03-05T21:37:45Z"
      end
    end
  end

  def test_note_author
    deleted_user = create(:user, :deleted)
    user = create(:user)

    assert_equal "", note_author(nil)

    assert_equal "deleted", note_author(deleted_user)

    note_author_dom = Rails::Dom::Testing.html_document_fragment.parse note_author(user)
    assert_dom note_author_dom, "a:root", :text => user.display_name do
      assert_dom "> @href", "/user/#{ERB::Util.u(user.display_name)}"
    end

    note_author_dom = Rails::Dom::Testing.html_document_fragment.parse note_author(user, :only_path => false)
    assert_dom note_author_dom, "a:root", :text => user.display_name do
      assert_dom "> @href", "http://test.host/user/#{ERB::Util.u(user.display_name)}"
    end
  end

  def test_note_list_row_class_created
    user = create(:user)
    note = create(:note)
    create(:note_comment, :note => note, :author => user)

    assert_equal "table-danger", note_list_row_class(note, user)
  end

  def test_note_list_row_class_created_and_resolved
    user = create(:user)
    note = create(:note)
    create(:note_comment, :note => note, :author => user)
    create(:note_comment, :note => note, :author => user, :event => "closed")

    assert_equal "table-warning", note_list_row_class(note, user)
  end

  def test_note_list_row_class_resolved
    user = create(:user)
    other_user = create(:user)
    note = create(:note)
    create(:note_comment, :note => note, :author => other_user)
    create(:note_comment, :note => note, :author => user, :event => "closed")

    assert_equal "table-success", note_list_row_class(note, user)
  end

  def test_note_list_row_class_resolved_and_reopened_by_other_user
    user = create(:user)
    other_user = create(:user)
    note = create(:note)
    create(:note_comment, :note => note, :author => other_user)
    create(:note_comment, :note => note, :author => user, :event => "closed")
    create(:note_comment, :note => note, :author => other_user, :event => "reopened")

    assert_nil note_list_row_class(note, user)
  end

  def test_note_list_row_class_commented
    user = create(:user)
    other_user = create(:user)
    note = create(:note)
    create(:note_comment, :note => note, :author => other_user)
    create(:note_comment, :note => note, :author => user, :event => "commented")

    assert_nil note_list_row_class(note, user)
  end
end
