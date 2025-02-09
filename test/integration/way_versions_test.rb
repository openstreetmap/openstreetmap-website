require "test_helper"

class WayVersionsTest < ActionDispatch::IntegrationTest
  ##
  # check that we can retrieve versions of a way
  def test_version
    way = create(:way, :with_history)
    used_way = create(:way, :with_history)
    create(:relation_member, :member => used_way)
    way_with_versions = create(:way, :with_history, :version => 4)

    create(:way_tag, :way => way)
    create(:way_tag, :way => used_way)
    create(:way_tag, :way => way_with_versions)
    propagate_tags(way, way.old_ways.last)
    propagate_tags(used_way, used_way.old_ways.last)
    propagate_tags(way_with_versions, way_with_versions.old_ways.last)

    check_current_version(way.id)
    check_current_version(used_way.id)
    check_current_version(way_with_versions.id)
  end

  private

  ##
  # check that the current version of a way is equivalent to the
  # version which we're getting from the versions call.
  def check_current_version(way_id)
    # get the current version
    current_way = with_controller(WaysController.new) do
      get api_way_path(way_id)
      assert_response :success, "can't get current way #{way_id}"
      Way.from_xml(@response.body)
    end
    assert_not_nil current_way, "getting way #{way_id} returned nil"

    # get the "old" version of the way from the version method
    get api_way_version_path(way_id, current_way.version)
    assert_response :success, "can't get old way #{way_id}, v#{current_way.version}"
    old_way = Way.from_xml(@response.body)

    # check that the ways are identical
    assert_ways_are_equal current_way, old_way
  end

  def propagate_tags(way, old_way)
    way.tags.each do |k, v|
      create(:old_way_tag, :old_way => old_way, :k => k, :v => v)
    end
  end
end
