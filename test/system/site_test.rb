require "application_system_test_case"

class SiteTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit "/"

    assert_selector "h1", :text => "OpenStreetMap"
  end

  test "note marker should have first comment as a title" do
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note, :latitude => position, :longitude => position) do |note|
      create(:note_comment, :note => note, :body => "Note description")
    end

    visit root_path(:anchor => "map=18/1.1/1.1&layers=N")
    all "img.leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "Note description", marker["title"]
    end
  end

  test "note marker should not have a title if the note has no visible comments" do
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note, :latitude => position, :longitude => position) do |note|
      create(:note_comment, :note => note, :body => "Note description is hidden", :visible => false)
    end

    visit root_path(:anchor => "map=18/1.1/1.1&layers=N")
    all "img.leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "", marker["title"]
    end
  end
end
