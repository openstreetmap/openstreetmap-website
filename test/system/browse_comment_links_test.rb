require "application_system_test_case"

class BrowseCommentLinksTest < ApplicationSystemTestCase
  test "visiting changeset comment link should pan to changeset" do
    changeset = create(:changeset, :min_lat => 60 * GeoRecord::SCALE, :min_lon => 30 * GeoRecord::SCALE,
                                   :max_lat => 60 * GeoRecord::SCALE, :max_lon => 30 * GeoRecord::SCALE)
    comment = create(:changeset_comment, :changeset => changeset, :body => "Linked changeset comment")

    visit changeset_path(changeset, :anchor => "c#{comment.id}")

    within_sidebar do
      assert_text "Linked changeset comment"
    end
    assert_match %r{map=\d+/60\.\d+/30\.\d+}, current_url
  end

  test "visiting note comment link should pan to note" do
    note = create(:note, :latitude => 59 * GeoRecord::SCALE, :longitude => 29 * GeoRecord::SCALE)
    create(:note_comment, :note => note, :body => "Note description")
    comment = create(:note_comment, :note => note, :body => "Linked note comment", :event => "commented")

    visit note_path(note, :anchor => "c#{comment.id}")

    within_sidebar do
      assert_text "Linked note comment"
    end
    assert_match %r{map=\d+/59\.\d+/29\.\d+}, current_url
  end
end
