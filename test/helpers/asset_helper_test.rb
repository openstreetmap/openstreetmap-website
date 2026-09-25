# frozen_string_literal: true

require "test_helper"

class AssetHelperTest < ActionView::TestCase
  def test_assets
    asset_map = assets("@openstreetmap/id")
    assert_kind_of Hash, asset_map
    assert_operator asset_map.length, :>, 0
  end
end
