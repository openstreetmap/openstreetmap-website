# frozen_string_literal: true

require "test_helper"

class IssuesHelperTest < ActionView::TestCase
  attr_accessor :current_user

  def test_reportable_heading_diary_comment
    create(:language, :code => "en")
    diary_entry = create(:diary_entry, :title => "A Discussion")
    diary_comment = create(:diary_comment, :diary_entry => diary_entry, :created_at => "2020-03-15", :updated_at => "2021-05-17")

    heading = reportable_heading diary_comment

    dom_heading = Rails::Dom::Testing.html_document_fragment.parse "<p>#{heading}</p>"
    assert_dom dom_heading, ":root", "Diary Comment A Discussion, comment ##{diary_comment.id} created on 15 March 2020 at 00:00, updated on 17 May 2021 at 00:00"
    assert_dom dom_heading, "a", 1 do
      assert_dom "> @href", diary_entry_url(diary_entry.user, diary_entry, :anchor => "comment#{diary_comment.id}")
    end
  end

  def test_reportable_heading_diary_entry
    create(:language, :code => "en")
    diary_entry = create(:diary_entry, :title => "Important Subject", :created_at => "2020-03-24", :updated_at => "2021-05-26")

    heading = reportable_heading diary_entry

    dom_heading = Rails::Dom::Testing.html_document_fragment.parse "<p>#{heading}</p>"
    assert_dom dom_heading, ":root", "Diary Entry Important Subject created on 24 March 2020 at 00:00, updated on 26 May 2021 at 00:00"
    assert_dom dom_heading, "a", 1 do
      assert_dom "> @href", diary_entry_url(diary_entry.user, diary_entry)
    end
  end

  def test_reportable_heading_note
    note = create(:note, :created_at => "2020-03-14", :updated_at => "2021-05-16")

    heading = reportable_heading note

    dom_heading = Rails::Dom::Testing.html_document_fragment.parse "<p>#{heading}</p>"
    assert_dom dom_heading, ":root", "Note ##{note.id} created on 14 March 2020 at 00:00, updated on 16 May 2021 at 00:00"
    assert_dom dom_heading, "a", 1 do
      assert_dom "> @href", note_url(note)
    end
  end

  def test_reportable_heading_user
    user = create(:user, :display_name => "Someone", :created_at => "2020-07-18")

    heading = reportable_heading user

    dom_heading = Rails::Dom::Testing.html_document_fragment.parse "<p>#{heading}</p>"
    assert_dom dom_heading, ":root", "User Someone created on 18 July 2020 at 00:00"
    assert_dom dom_heading, "a", 1 do
      assert_dom "> @href", user_url(user)
    end
  end

  def test_issues_count
    target_user = create(:user)
    self.current_user = create(:moderator_user)

    n = (Settings.max_issues_count - 1)
    n.times do
      create(:note_with_comments) do |note|
        create(:issue, :reportable => note, :reported_user => target_user, :assigned_role => "moderator")
      end
    end
    expected = <<~HTML.delete("\n")
      <span class="badge count-number">#{n}</span>
    HTML
    assert_dom_equal expected, open_issues_count

    n += 1
    create(:note_with_comments) do |note|
      create(:issue, :reportable => note, :reported_user => target_user, :assigned_role => "moderator")
    end
    expected = <<~HTML.delete("\n")
      <span class="badge count-number">#{n}+</span>
    HTML
    assert_dom_equal expected, open_issues_count
  end
end
