# frozen_string_literal: true

require "application_system_test_case"

class NoteLayerTest < ApplicationSystemTestCase
  test "note marker should have description as a title" do
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note, :latitude => position, :longitude => position) do |note|
      create(:note_comment, :note => note, :body => "Note description", :event => "opened")
    end

    visit root_path(:anchor => "map=18/1.1/1.1&layers=N")
    all ".leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "Note description", marker["title"]
    end
  end

  test "note marker should not have a title if the note has no visible description" do
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note, :latitude => position, :longitude => position) do |note|
      create(:note_comment, :note => note, :body => "Note description is hidden", :event => "opened", :visible => false)
      create(:note_comment, :note => note, :body => "Note comment visible")
    end

    visit root_path(:anchor => "map=18/1.1/1.1&layers=N")
    all ".leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "", marker["title"]
    end
  end

  test "note marker should not have a title if the note has no visible description and comments" do
    position = (1.1 * GeoRecord::SCALE).to_i
    create(:note, :latitude => position, :longitude => position) do |note|
      create(:note_comment, :note => note, :body => "Note description is hidden", :event => "opened", :visible => false)
    end

    visit root_path(:anchor => "map=18/1.1/1.1&layers=N")
    all ".leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "", marker["title"]
    end
  end
end
