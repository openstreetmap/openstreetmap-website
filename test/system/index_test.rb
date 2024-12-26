require "application_system_test_case"

class IndexTest < ApplicationSystemTestCase
  test "should remove and add an overlay on share button click" do
    node = create(:node)
    visit node_path(node)
    assert_selector "#content.overlay-right-sidebar"
    find(".icon.share").click
    assert_no_selector "#content.overlay-right-sidebar"
    find(".icon.share").click
    assert_selector "#content.overlay-right-sidebar"
  end

  test "should add an overlay on close" do
    node = create(:node)
    visit node_path(node)
    find(".icon.share").click
    assert_no_selector "#content.overlay-right-sidebar"
    find(".share-ui .btn-close").click
    assert_selector "#content.overlay-right-sidebar"
  end

  test "should not add overlay when not closing right menu popup" do
    node = create(:node)
    visit node_path(node)
    find(".icon.share").click

    find(".icon.key").click
    assert_no_selector "#content.overlay-right-sidebar"
    find(".icon.layers").click
    assert_no_selector "#content.overlay-right-sidebar"
    find(".icon.key").click
    assert_no_selector "#content.overlay-right-sidebar"

    find(".icon.key").click
    assert_selector "#content.overlay-right-sidebar"
  end

  test "node included in edit link" do
    node = create(:node)
    visit node_path(node)
    assert_selector "#editanchor[href*='?node=#{node.id}#']"

    find("#sidebar .btn-close").click
    assert_no_selector "#editanchor[href*='?node=#{node.id}#']"
  end

  test "note included in edit link" do
    note = create(:note_with_comments)
    visit note_path(note)
    assert_selector "#editanchor[href*='?note=#{note.id}#']"

    find("#sidebar .btn-close").click
    assert_no_selector "#editanchor[href*='?note=#{note.id}#']"
  end

  test "can navigate from hidden note to visible note" do
    sign_in_as(create(:moderator_user))
    hidden_note = create(:note, :status => "hidden", :description => "this-is-a-hidden-note")
    create(:note_comment, :note => hidden_note, :event => "opened", :body => "")
    position = (1.003 * GeoRecord::SCALE).to_i
    visible_note = create(:note, :latitude => position, :longitude => position, :description => "this-is-a-visible-note")
    create(:note_comment, :note => visible_note, :event => "opened", :body => "")

    visit root_path(:anchor => "map=15/1/1") # view place of hidden note in case it is not rendered during note_path(hidden_note)
    visit note_path(hidden_note)
    find(".leaflet-control.control-layers .control-button").click
    find("#map-ui .overlay-layers .form-check-label", :text => "Map Notes").click
    visible_note_marker = find(".leaflet-marker-icon[title=this-is-a-visible-note]")
    assert_selector "#sidebar", :text => "this-is-a-hidden-note"

    visible_note_marker.click
    assert_selector "#sidebar", :text => "this-is-a-visible-note"
  end
end
